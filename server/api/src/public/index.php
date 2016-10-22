<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

use \Psr\Http\Message\ServerRequestInterface as Request;
use \Psr\Http\Message\ResponseInterface as Response;

require '../vendor/autoload.php';

spl_autoload_register(function ($classname) {
    require ("../classes/" . $classname . ".php");
});

$config['displayErrorDetails'] = true;
$config['addContentLengthHeader'] = false;
/*
$config['db']['host']   = "db645859868.db.1and1.com";
$config['db']['port']   = "3306";
$config['db']['user']   = "dbo645859868";
$config['db']['pass']   = "lowres.82";
$config['db']['dbname'] = "db645859868";
*/
$config['db']['host']   = "localhost";
$config['db']['port']   = "8889";
$config['db']['user']   = "root";
$config['db']['pass']   = "root";
$config['db']['dbname'] = "lowres";

$config['lowres']['filesurl'] = "lowresfiles.timokloss.com";
$config['lowres']['filespath'] = "../../lowresfiles";

$app = new \Slim\App(["settings" => $config]);
$container = $app->getContainer();

$container['db'] = function ($c) {
    $db = $c['settings']['db'];
    $pdo = new PDO("mysql:host=" . $db['host'] . ";port=" . $db['port'] . ";dbname=" . $db['dbname'] . ';charset=utf8mb4',
        $db['user'], $db['pass']);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    return $pdo;
};


// Fields defaults
define("MIN_POST_FIELDS", "type, category, user, title, image, sharedPost, stats");
define("MIN_USER_FIELDS", "username");
define("FULL_USER_FIELDS", "username, lastPostDate, notificationsOpenedDate, about");


// get post
$app->get('/posts/{id}', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $postId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $post = $access->addObject("posts", "post", $postId);
    if ($post !== FALSE) {
        $user = $access->addObject("users", "user", $post['user'], MIN_USER_FIELDS);
        $stats = $access->addObject("postStats", "stats", $post['stats']);

        if (!empty($params['likedUserId'])) {
            $access->data['liked'] = $access->userLikesPost($params['likedUserId'], $postId);
        }

        $stmt = $access->prepareMainStatement("comments", $params, "*", "WHERE post = ? ORDER BY createdAt ASC");
        $stmt->bindValue(1, $postId);
        $comments = $access->addObjects($stmt, "comments");
        if ($comments !== FALSE) {
            $access->addSubObjects($comments, "user", "users", MIN_USER_FIELDS);
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// add post comment
$app->post('/posts/{id}/comments', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $postId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $body['post'] = $postId;
    if ($access->createObject("comments", $body) !== FALSE) {
        $access->increasePostStats($postId, 0, 1, 0);
    }

    $response = $response->withJson($access->data);
    return $response;
});

// add post like
$app->post('/posts/{id}/likes', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $postId = $request->getAttribute('id');
    $userId = $body['user'];
    $access = new DataBaseAccess($this->db);

    if (userLikesPost($userId, $postId)) {
        $access->setError("AlreadyLiked", "You already like this post.");
    } else {
        $body['post'] = $postId;
        if ($access->createObject("likes", $body) !== FALSE) {
            $access->increasePostStats($postId, 0, 0, 1);
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// add post download
$app->post('/posts/{id}/downloads', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $postId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $access->increasePostStats($postId, 1, 0, 0);

    $response = $response->withJson($access->data);
    return $response;
});

// get all posts
$app->get('/posts', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $access = new DataBaseAccess($this->db);

    $stmt = $access->prepareMainStatement("posts", $params, MIN_POST_FIELDS, "ORDER BY createdAt DESC");
    $posts = $access->addObjects($stmt, "posts");
    if ($posts !== FALSE) {
        if ($access->addSubObjects($posts, "user", "users", MIN_USER_FIELDS)) {
            $access->addSubObjects($posts, "stats", "postStats");
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// get user news
$app->get('/users/{id}/news', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    //TODO posts of followed users

    $response = $response->withJson($access->data);
    return $response;
});

// get user notifications
$app->get('/users/{id}/notifications', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $stmt = $access->prepareMainStatement("notifications", $params, "*", "WHERE recipient = ? ORDER BY createdAt DESC");
    $stmt->bindValue(1, $userId);
    $notifications = $access->addObjects($stmt, "notifications");
    if ($notifications !== FALSE) {
        $access->addSubObjects($notifications, "post", "posts", "title");
        $access->addSubObjects($notifications, "sender", "users", MIN_USER_FIELDS);
    }

    $response = $response->withJson($access->data);
    return $response;
});

// get users followed by user
$app->get('/users/{id}/following', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $access->addFollowUsers($userId, FALSE);

    $response = $response->withJson($access->data);
    return $response;
});

// get user followers
$app->get('/users/{id}/followers', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $access->addFollowUsers($userId, TRUE);

    $response = $response->withJson($access->data);
    return $response;
});

// get user posts
$app->get('/users/{id}/posts', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $stmt = $access->prepareMainStatement("posts", $params, MIN_POST_FIELDS, "WHERE user = ? ORDER BY createdAt DESC");
    $stmt->bindValue(1, $userId);
    $posts = $access->addObjects($stmt, "posts");
    if ($posts !== FALSE) {
        $access->addSubObjects($posts, "stats", "postStats");
    }

    $response = $response->withJson($access->data);
    return $response;
});

// add user post
$app->post('/users/{id}/posts', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $body['user'] = $userId;
    $postId = $access->createObject("posts", $body);
    if ($postId !== FALSE) {
        $statsId = $access->createObject("postStats", array('post' => $postId), "postStats");
        if ($statsId !== FALSE) {
            $stmt = $this->db->prepare("UPDATE posts SET stats = ? WHERE objectId = ?");
            $stmt->bindParam(1, $statsId);
            $stmt->bindParam(2, $postId);
            if ($stmt->execute()) {
            } else {
                $access->setSQLError($stmt);
            }
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// get user
$app->get('/users/{id}', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $user = $access->addObject("users", "user", $userId, FULL_USER_FIELDS);
    if ($user !== FALSE) {
        $stmt = $access->prepareMainStatement("posts", $params, MIN_POST_FIELDS, "WHERE user = ? ORDER BY createdAt DESC");
        $stmt->bindValue(1, $userId);
        $posts = $access->addObjects($stmt, "posts");
        if ($posts !== FALSE) {
            $access->addSubObjects($posts, "stats", "postStats");
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// Files

// save file
$app->post('/files/{name}', function (Request $request, Response $response) {
    $name = basename($request->getAttribute('name'));
    $body = $request->getBody();
    $settings = $this->get('settings')['lowres'];
    $data = array();

    if ($body->getSize() > 5 * 1024 * 1024) {
        $data['error'] =  array('message' => "The uploaded file is too large.", 'type' => "FileTooLarge");
    } else {
        $uniqueName = "lrc-".md5(microtime())."-".$name;

        file_put_contents($settings['filespath']."/".$uniqueName, $body);

        $data['name'] = $uniqueName;
        $data['url'] = $settings['filesurl']."/".$uniqueName;
    }

    $response = $response->withJson($data);
    return $response;
});

// Login

$app->get('/login', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $username = $params['username'];
    $password = $params['password'];

    $access = new DataBaseAccess($this->db);

    $stmt = $this->db->prepare("SELECT * FROM users WHERE username = ?");
    $stmt->bindParam(1, $username);
    if ($stmt->execute()) {
        $user = $stmt->fetch();
        if ($user == NULL) {
            $access->setError("InvalidLogin", "The username or password is invalid.");
        } else {
            $valid = password_verify($password, $user['bcryptPassword']);
            if ($valid) {
                unset($user['bcryptPassword']);
                $access->data['user'] = $user;
            } else {
                $access->setError("InvalidLogin", "The username or password is invalid.");
            }
        }
    } else {
        $access->setSQLError($stmt);
    }
    $response = $response->withJson($access->data);
    return $response;
});

$app->run();
?>