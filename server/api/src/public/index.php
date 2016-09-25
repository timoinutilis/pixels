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

$app->get('/hello/{name}', function (Request $request, Response $response) {
	//$request->getQueryParams()
    $name = $request->getAttribute('name');
    $response->getBody()->write("Hello, $name");
    return $response;
});

$app->get('/posts', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $access = new DataBaseAccess($this->db);

    $posts = $access->addMainObjects("posts", $params);
    if ($posts !== FALSE) {
        if ($access->addSubObjects($posts, "user", "users")) {
            $access->addSubObjects($posts, "stats", "postStats");
        }
    }

    $response->getBody()->write(json_encode($access->data, JSON_PRETTY_PRINT));
    return $response;
});

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
            $valid = password_verify($password, $user["bcryptPassword"]);
            if ($valid) {
                $access->data['user'] = $user;
            } else {
                $access->setError("InvalidLogin", "The username or password is invalid.");
            }
        }
    } else {
        $access->setError("SQL", $stmt->errorInfo()[2]);
    }
    $response->getBody()->write(json_encode($access->data, JSON_PRETTY_PRINT));
    return $response;
});

$app->run();
?>