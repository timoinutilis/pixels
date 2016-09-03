<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

echo "import\n";

$pdo = new PDO("mysql:host=localhost;port=8889;dbname=lowres;charset=utf8", "root", "root");
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

$json_dir = "./json/";
$files_dir = "./files/";

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

// Posts

$s = $pdo->prepare("INSERT INTO posts (objectId,updatedAt,createdAt,type,category,user,title,detail,image,program,sharedPost) VALUES (?,?,?,?,?,?,?,?,?,?,?)");

$results = load_json_results("Post.json");
$old_programs = load_json_by_ids("Program.json");
foreach ($results as $post) {
	$is_original = true;
	$sharedPost = NULL;
	$image = NULL;
	$program = NULL;
	$detail = NULL;
	if (!empty($post->sharedPost)) {
		$sharedPost = $post->sharedPost->objectId;
		$is_original = false;
	}
	if (!empty($post->image)) {
		$image = $post->image->name;
		if ($is_original) {
			file_put_contents($files_dir.$image, fopen($post->image->url, 'r'));
		}
	}
	if ($is_original) {
		// shared posts don't need these values
		if (!empty($post->programFile)) {
			// download program file
			$program = $post->programFile->name;
			file_put_contents($files_dir.$program, fopen($post->programFile->url, 'r'));
		}
		else if (!empty($post->program)) {
			// get old program from db and save to file
			$old_program = $old_programs[$post->program->objectId];
			$program = "lrc-".md5(microtime())."-".file_title($post->title).".txt";
			file_put_contents($files_dir.$program, $old_program->sourceCode);
		}
		$detail = $post->detail;
	}
	$values = array($post->objectId, $post->updatedAt, $post->createdAt, $post->type, $post->category, $post->user->objectId, $post->title, $detail, $image, $program, $sharedPost);
	$s->execute($values);
}

echo "done\n";
?>