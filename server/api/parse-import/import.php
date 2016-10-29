<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

echo "import\n";

$pdo = new PDO("mysql:host=localhost;port=8889;dbname=lowres;charset=utf8", "root", "root"); //TODO utf8mb??
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

$json_dir = "./json/";
$files_dir = "./files/";

import_users();
import_posts();
import_comments();
import_post_stats();
import_likes();
import_follows();
import_notifications();

echo "done\n";

function load_json_results($name) {
	global $json_dir;
	$datatext = file_get_contents($json_dir.$name);
	$data = json_decode($datatext);
	return $data->results;
}

function load_json_by_ids($name) {
	$results = load_json_results($name);
	$objects = array();
	foreach ($results as $object) {
		$objects[$object->objectId] = $object;
	}
	return $objects;
}

function file_title($title) {
	$regex = '#[^a-zA-Z0-9_]#i';
	$title = preg_replace($regex, '', $title);
    if (strlen($title) > 30) {
        $title = substr($title, 0, 30);
    }
    return $title;
}

function import_users() {
	global $pdo;
	$s = $pdo->prepare("INSERT INTO Users (objectId,updatedAt,createdAt,username,bcryptPassword,sessionToken,lastPostDate,notificationsOpenedDate,about) VALUES (?,?,?,?,?,?,?,?,?)");
	$results = load_json_results("_User.json");
	foreach ($results as $object) {
		$sessionToken = NULL;
		$lastPostDate = NULL;
		$notificationsOpenedDate = NULL;
		$about = NULL;
		if (!empty($object->sessionToken)) {
			$sessionToken = $object->sessionToken;
		}
		if (!empty($object->lastPostDate)) {
			$lastPostDate = $object->lastPostDate->iso;
		}
		if (!empty($object->notificationsOpenedDate)) {
			$notificationsOpenedDate = $object->notificationsOpenedDate->iso;
		}
		if (!empty($object->about)) {
			$about = $object->about;
		}
		$values = array($object->objectId, $object->updatedAt, $object->createdAt, $object->username, $object->bcryptPassword, $sessionToken, $lastPostDate, $notificationsOpenedDate, $about);
		$s->execute($values);
	}
}

function import_posts() {
	global $pdo, $files_dir;
	$s = $pdo->prepare("INSERT INTO Posts (objectId,updatedAt,createdAt,type,category,user,title,detail,image,program,sharedPost,stats) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
	$results = load_json_results("Post.json");
	$old_programs = load_json_by_ids("Program.json");
	foreach ($results as $object) {
		$is_original = true;
		$sharedPost = NULL;
		$image = NULL;
		$program = NULL;
		$detail = NULL;
		if (!empty($object->sharedPost)) {
			$sharedPost = $object->sharedPost->objectId;
			$is_original = false;
		}
		if (!empty($object->image)) {
			$image = $object->image->name;
			if ($is_original) {
				file_put_contents($files_dir.$image, fopen($object->image->url, 'r'));
			}
		}
		if ($is_original) {
			// shared posts don't need these values
			if (!empty($object->programFile)) {
				// download program file
				$program = $object->programFile->name;
				file_put_contents($files_dir.$program, fopen($object->programFile->url, 'r'));
			}
			else if (!empty($object->program)) {
				// get old program from db and save to file
				$old_program = $old_programs[$object->program->objectId];
				$program = "lrc-".bin2hex(openssl_random_pseudo_bytes(16))."-".file_title($object->title).".txt";
				file_put_contents($files_dir.$program, $old_program->sourceCode);
			}
			$detail = $object->detail;
		}
		$values = array($object->objectId, $object->updatedAt, $object->createdAt, $object->type, $object->category, $object->user->objectId, $object->title, $detail, $image, $program, $sharedPost, $object->stats->objectId);
		$s->execute($values);
	}
}

function import_comments() {
	global $pdo;
	$s = $pdo->prepare("INSERT INTO Comments (objectId,updatedAt,createdAt,post,user,text) VALUES (?,?,?,?,?,?)");
	$results = load_json_results("Comment.json");
	foreach ($results as $object) {
		$user = NULL;
		if (!empty($object->user)) {
			$user = $object->user->objectId;
		}
		$values = array($object->objectId, $object->updatedAt, $object->createdAt, $object->post->objectId, $user, $object->text);
		$s->execute($values);
	}
}

function import_post_stats() {
	global $pdo;
	$s = $pdo->prepare("INSERT INTO PostStats (objectId,updatedAt,createdAt,numDownloads,numComments,numLikes) VALUES (?,?,?,?,?,?)");
	$results = load_json_results("PostStats.json");
	foreach ($results as $object) {
		$numDownloads = 0;
		$numComments = 0;
		$numLikes = 0;
		if (!empty($object->numDownloads)) {
			$numDownloads = $object->numDownloads;
		}
		if (!empty($object->numComments)) {
			$numComments = $object->numComments;
		}
		if (!empty($object->numLikes)) {
			$numLikes = $object->numLikes;
		}
		$values = array($object->objectId, $object->updatedAt, $object->createdAt, $numDownloads, $numComments, $numLikes);
		$s->execute($values);
	}
}

function import_likes() {
	global $pdo;
	$s = $pdo->prepare("INSERT INTO Likes (objectId,updatedAt,createdAt,post,user) VALUES (?,?,?,?,?)");
	$results = load_json_results("Count.json");
	foreach ($results as $object) {
		if ($object->type == 1) { // Count type "like"
			$values = array($object->objectId, $object->updatedAt, $object->createdAt, $object->post->objectId, $object->user->objectId);
			$s->execute($values);
		}
	}
}

function import_follows() {
	global $pdo;
	$s = $pdo->prepare("INSERT INTO Follows (objectId,updatedAt,createdAt,user,followsUser) VALUES (?,?,?,?,?)");
	$results = load_json_results("Follow.json");
	foreach ($results as $object) {
		$user = NULL;
		$values = array($object->objectId, $object->updatedAt, $object->createdAt, $object->user->objectId, $object->followsUser->objectId);
		$s->execute($values);
	}
}

function import_notifications() {
	global $pdo;
	$s = $pdo->prepare("INSERT INTO Notifications (objectId,updatedAt,createdAt,sender,recipient,post,type) VALUES (?,?,?,?,?,?,?)");
	$results = load_json_results("Notification.json");
	foreach ($results as $object) {
		$post = NULL;
		if (!empty($object->post)) {
			$post = $object->post->objectId;
		}
		$values = array($object->objectId, $object->updatedAt, $object->createdAt, $object->sender->objectId, $object->recipient->objectId, $post, $object->type);
		$s->execute($values);
	}
}

?>