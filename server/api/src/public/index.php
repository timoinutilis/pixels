<?php
use \Psr\Http\Message\ServerRequestInterface as Request;
use \Psr\Http\Message\ResponseInterface as Response;

require '../vendor/autoload.php';

spl_autoload_register(function ($classname) {
    require ("../classes/" . $classname . ".php");
});

/* ============ Config ============ */

$config['displayErrorDetails'] = true;
$config['addContentLengthHeader'] = false;

if ($_SERVER['SERVER_NAME'] == "localhost") {
    $config['db']['host']   = "localhost";
    $config['db']['port']   = "8889";
    $config['db']['user']   = "root";
    $config['db']['pass']   = "root";
    $config['db']['dbname'] = "lowres";
} else {
    $config['db']['host']   = "db645859868.db.1and1.com";
    $config['db']['port']   = "3306";
    $config['db']['user']   = "dbo645859868";
    $config['db']['pass']   = "lowres.82";
    $config['db']['dbname'] = "db645859868";
}

$config['lowres']['filesurl'] = "http://lowresfiles.timokloss.com";
$config['lowres']['filespath'] = "../../lowresfiles";
$config['lowres']['admin'] = "T5VWaLW28x";

/* ============ Slim App ============ */

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

/* ============ Error Handlers ============ */

$container['errorHandler'] = function ($c) {
    return function ($request, $response, $exception) use ($c) {
        if ($exception instanceof APIException) {
            $data = array('error' => array('message' => $exception->getMessage(), 'type' => $exception->getType()));
            return $c['response']->withStatus($exception->getCode())->withJson($data);
        } else {
            $data = array('error' => array('message' => "Something went wrong on the server.", 'details' => $exception->getMessage(), 'type' => "InternalServerError"));
            return $c['response']->withStatus(500)->withJson($data);
        }
    };
};

$container['notFoundHandler'] = function ($c) {
    return function ($request, $response) use ($c) {
        $data = array('error' => array('message' => "This route is unknown.", 'type' => "NotFound"));
        return $c['response']->withStatus(404)->withJson($data);
    };
};

$container['notAllowedHandler'] = function ($c) {
    return function ($request, $response, $methods) use ($c) {
        $data = array('error' => array('message' => "Method must be one of: " . implode(", ", $methods), 'type' => "MethodNotAllowed"));
        return $c['response']->withStatus(405)
                             ->withHeader('Allow', implode(', ', $methods))
                             ->withJson($data);
    };
};

/* ============ Defines ============ */

// Fields defaults
define("MIN_POST_FIELDS", "objectId, updatedAt, createdAt, type, category, user, title, image, sharedPost, stats");
define("MIN_POST_JOIN_FIELDS", "p.objectId, p.updatedAt, p.createdAt, p.type, p.category, p.user, p.title, p.image, p.sharedPost, p.stats");
define("MIN_USER_FIELDS", "username");
define("FULL_USER_FIELDS", "username, lastPostDate, notificationsOpenedDate, about");

define("GUEST_USER_ID", "guest");

define("DISCOVER_EXCLUDED_POSTS", "'GdoDgxb4tF'");

define("NotificationTypeComment", 0);
define("NotificationTypeLike", 1);
define("NotificationTypeShare", 2);
define("NotificationTypeFollow", 3);

define("PostTypeProgram", 1);
define("PostTypeStatus", 2);
define("PostTypeShare", 3);
define("PostTypeForum", 4);

define("UserRoleUser", 0);
define("UserRoleModerator", 1);
define("UserRoleAdmin", 2);

define("NormalPostTypes", "1,2,3");

/* ============ Parameter Checks ============ */

function checkMyUser($userId, Request $request) {
    $currentUser = $request->getAttribute('currentUser');
    if (empty($userId) || empty($currentUser) || $userId != $currentUser) {
        throw new APIException("You don't have the permission for this.", 403, "Forbidden");
    }
}

function checkNewPassword($password) {
    if (empty($password) || strlen($password) < 6) {
        throw new APIException("Choose a password with 6 or more characters.", 403, "BadPassword");
    }
}

function checkNewUsername($username) {
    if (empty($username) || strlen($username) < 4) {
        throw new APIException("Choose a username with 4 or more characters.", 403, "BadUsername");
    }
}

function checkRequired($body, $key) {
    if (empty($body[$key])) {
        throw new APIException("Missing parameter '$key'.", 400, "MissingParameter");
    }
}

function checkUserPermission($allowedUserIds, $masterUserRole, Request $request, DataBaseAccess $access) {
    $currentUserId = $request->getAttribute('currentUser');

    if (empty($currentUserId)) {
        throw new APIException("You don't have the permission for this.", 403, "Forbidden");
    }

    if (array_search($currentUserId, $allowedUserIds) !== FALSE) {
        return;
    }

    $currentUser = $access->getObject("users", $currentUserId);
    if ($currentUser) {
        if ($currentUser['role'] < $masterUserRole) {
            throw new APIException("You don't have the permission for this.", 403, "Forbidden");
        }
    } else {
        throw new APIException("The object '$currentUserId' could not be found.", 404, "NotFound");
    }
}

/* ============ Routes ============ */

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

        $stmt = $access->prepareMainStatement("SELECT * FROM comments WHERE post = ? ORDER BY createdAt ASC", $params);
        $stmt->bindValue(1, $postId);
        $comments = $access->addObjects($stmt, "comments");
        if ($comments !== FALSE) {
            $access->addSubObjects($comments, "user", "users", MIN_USER_FIELDS);
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// delete post
$app->delete('/posts/{id}', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $postId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $post = $access->getObject("posts", $postId);
    if ($post) {
        checkUserPermission(array($post['user']), UserRoleModerator, $request, $access);

        $stmt = $this->db->prepare("DELETE FROM posts WHERE sharedPost = ?");
        $stmt->bindValue(1, $postId);
        if ($stmt->execute()) {
            $stmt = $this->db->prepare("DELETE FROM comments WHERE post = ?");
            $stmt->bindValue(1, $postId);
            if ($stmt->execute()) {
                $stmt = $this->db->prepare("DELETE FROM likes WHERE post = ?");
                $stmt->bindValue(1, $postId);
                if ($stmt->execute()) {
                    $stmt = $this->db->prepare("DELETE FROM notifications WHERE post = ?");
                    $stmt->bindValue(1, $postId);
                    if ($stmt->execute()) {
                        $stmt = $this->db->prepare("DELETE FROM posts WHERE objectId = ?");
                        $stmt->bindValue(1, $postId);
                        if ($stmt->execute()) {
                            //TODO delete files
                            $access->data['success'] = TRUE;
                            
                            if ($post['type'] == PostTypeShare) {
                                // remove featured mark from original post
                                $stmt = $this->db->prepare("UPDATE postStats SET featured = FALSE WHERE post = ?");
                                $stmt->bindValue(1, $post['sharedPost']);
                                $stmt->execute();
                            } else {
                                $stmt = $this->db->prepare("DELETE FROM postStats WHERE post = ?");
                                $stmt->bindValue(1, $postId);
                                $stmt->execute();
                            }
                        }
                    }
                }
            }
        }
    } else {
        throw new APIException("The object '$postId' could not be found.", 404, "NotFound");
    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// add post comment
$app->post('/posts/{id}/comments', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $postId = $request->getAttribute('id');
    $myUserId = $body['user'];
    $access = new DataBaseAccess($this->db);

    checkMyUser($myUserId, $request);
    checkRequired($body, 'text');

    $body['post'] = $postId;
    if ($access->createObject("comments", $body, "comment") !== FALSE) {
        $access->data['comment']['post'] = $postId;
        $response = $response->withStatus(201);
        $access->increasePostStats($postId, 0, 1, 0);

        // notifications...
        $post = $access->getObject("posts", $postId, "user");
        if ($post) {
            $postUserId = $post['user'];

            $recipientIds = array();

            // post owner
            if ($postUserId != $myUserId) {
                $recipientIds[] = $postUserId;
            }

            // other comments' users
            $stmt = $this->db->prepare("SELECT user FROM comments WHERE post = ? GROUP BY user");
            $stmt->bindParam(1, $postId);
            if ($stmt->execute()) {
                while ($otherComment = $stmt->fetch()) {
                    $otherUserId = $otherComment['user'];
                    if ($otherUserId != $myUserId && $otherUserId != $postUserId) {
                        $recipientIds[] = $otherUserId;
                    }
                }
            }

            $access->createNotification($myUserId, $recipientIds, $postId, NotificationTypeComment);
        }
    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// add post like
$app->post('/posts/{id}/likes', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $postId = $request->getAttribute('id');
    $userId = $body['user'];
    $access = new DataBaseAccess($this->db);

    checkMyUser($userId, $request);

    if ($access->userLikesPost($userId, $postId)) {
        throw new APIException("You already like this post.", 403, "AlreadyLiked");
    } else {
        $body['post'] = $postId;
        if ($access->createObject("likes", $body, "like") !== FALSE) {
            $access->data['like']['post'] = $postId;
            $response = $response->withStatus(201);
            $access->increasePostStats($postId, 0, 0, 1);

            $post = $access->getObject("posts", $postId, "user");
            if ($post) {
                $access->createNotification($userId, array($post['user']), $postId, NotificationTypeLike);
            }
        }
    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// add post download
$app->post('/posts/{id}/downloads', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $postId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $access->increasePostStats($postId, 1, 0, 0);

    $response = $response->withJson($access->data);
    return $response;
});

// delete comment
$app->delete('/comments/{id}', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $commentId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $comment = $access->getObject("comments", $commentId);
    if ($comment) {
        $postId = $comment['post'];
        $commentUserId = $comment['user'];

        $post = $access->getObject("posts", $postId);
        if ($post) {
            $postUserId = $post['user'];
            checkUserPermission(array($postUserId, $commentUserId), UserRoleModerator, $request, $access);

            $stmt = $this->db->prepare("DELETE FROM comments WHERE objectId = ?");
            $stmt->bindValue(1, $commentId);
            if ($stmt->execute()) {
                $access->increasePostStats($postId, 0, -1, 0);
                $access->data['success'] = TRUE;
            }
        } else {
            throw new APIException("The object '$postId' could not be found.", 404, "NotFound");
        }
    } else {
        throw new APIException("The object '$commentId' could not be found.", 404, "NotFound");
    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// get all posts
$app->get('/posts', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $access = new DataBaseAccess($this->db);

    $filter = $access->getPostsFilter($params, "WHERE");
    $stmt = $access->prepareMainStatement("SELECT ".MIN_POST_FIELDS." FROM posts $filter ORDER BY createdAt DESC", $params);
    $posts = $access->addObjects($stmt, "posts");
    if ($posts !== FALSE) {
        if ($access->addSubObjects($posts, "user", "users", MIN_USER_FIELDS)) {
            $access->addSubObjects($posts, "stats", "postStats");
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// get all forum posts
$app->get('/forum', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $access = new DataBaseAccess($this->db);

    $filter = $access->getPostsFilter($params, "AND");
    $stmt = $access->prepareMainStatement("SELECT ".MIN_POST_FIELDS." FROM posts WHERE type = ".PostTypeForum." $filter ORDER BY createdAt DESC", $params);
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
    $settings = $this->get('settings')['lowres'];
    $access = new DataBaseAccess($this->db);

    $adminId = $settings['admin'];
    $followedUserIds = ($userId == GUEST_USER_ID) ? array($adminId) : $access->getFollowedUserIds($userId);
    if ($followedUserIds !== FALSE) {
        $followedUserIdsString = "'".implode("','", $followedUserIds)."'";
        $sql = "SELECT ".MIN_POST_JOIN_FIELDS." FROM posts p";
        $sql .= " INNER JOIN postStats s ON p.stats = s.objectId";
        $sql .= " LEFT OUTER JOIN posts sh ON p.sharedPost = sh.objectId";
        $sql .= " WHERE p.user IN ($followedUserIdsString)";
        $sql .= " AND p.type IN (".NormalPostTypes.")";
        $sql .= " AND (p.sharedPost IS NULL OR sh.user NOT IN ($followedUserIdsString))"; // show shared posts only if not following their original users
        $filter = $access->getPostsFilter($params, " AND", "p.");
        if ($filter != "") {
            $sql .= $filter;
        }
        $sql .= " ORDER BY p.createdAt DESC";

        $stmt = $access->prepareMainStatement($sql, $params);
        $posts = $access->addObjects($stmt, "posts");
        if ($posts !== FALSE) {
            if ($access->addSubObjects($posts, "user", "users", MIN_USER_FIELDS)) {
                $access->addSubObjects($posts, "stats", "postStats");
            }
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// get user discover posts
$app->get('/users/{id}/discover', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $excludedUserIds = $access->getFollowedUserIds($userId);
    if ($excludedUserIds !== FALSE) {
        $excludedUserIds[] = $userId;
        $excludedUserIdsString = "'".implode("','", $excludedUserIds)."'";

        $sql = "SELECT ".MIN_POST_JOIN_FIELDS." FROM posts p";
        $sql .= " INNER JOIN postStats s ON p.stats = s.objectId";
        $sql .= " WHERE p.user NOT IN ($excludedUserIdsString)";
        $sql .= " AND p.type IN (".NormalPostTypes.")";
        $sql .= " AND s.featured = FALSE";
        $sql .= " AND p.objectId NOT IN (".DISCOVER_EXCLUDED_POSTS.")";
        $filter = $access->getPostsFilter($params, " AND", "p.");
        if ($filter != "") {
            $sql .= $filter;
        }
        $sql .= " ORDER BY p.createdAt DESC";

        $stmt = $access->prepareMainStatement($sql, $params);
        $posts = $access->addObjects($stmt, "posts");
        if ($posts !== FALSE) {
            if ($access->addSubObjects($posts, "user", "users", MIN_USER_FIELDS)) {
                $access->addSubObjects($posts, "stats", "postStats");
            }
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// get user notifications
$app->get('/users/{id}/notifications', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);
    
    $options = "recipient = ?";
    if (!empty($params['after'])) {
        $options .= " AND createdAt > ?";
    }

    $stmt = $access->prepareMainStatement("SELECT * FROM notifications WHERE $options ORDER BY createdAt DESC", $params);
    $stmt->bindValue(1, $userId);
    if (!empty($params['after'])) {
        $stmt->bindValue(2, $params['after']);
    }
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

// start following user
$app->post('/users/{id}/followers', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $userId = $request->getAttribute('id');
    $myUserId = $body['user'];
    $access = new DataBaseAccess($this->db);

    checkMyUser($myUserId, $request);

    $followsObject = array('user' => $myUserId, 'followsUser' => $userId);
    $followId = $access->createObject("follows", $followsObject, "follow");
    if ($followId !== FALSE) {
        $access->data['follow']['followsUser'] = $userId;
        $access->createNotification($myUserId, array($userId), NULL, NotificationTypeFollow);
        $response = $response->withStatus(201);
    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// stop following user
$app->delete('/users/{id}/followers/{myId}', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $userId = $request->getAttribute('id');
    $myUserId = $request->getAttribute('myId');
    $access = new DataBaseAccess($this->db);

    checkMyUser($myUserId, $request);

    $stmt = $this->db->prepare("DELETE FROM follows WHERE user = ? AND followsUser = ?");
    $stmt->bindValue(1, $myUserId);
    $stmt->bindValue(2, $userId);
    if ($stmt->execute()) {
        $access->data['success'] = TRUE;
    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// get user posts
$app->get('/users/{id}/posts', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $filter = $access->getPostsFilter($params, "AND");
    $stmt = $access->prepareMainStatement("SELECT ".MIN_POST_FIELDS." FROM posts WHERE user = ? AND type IN (".NormalPostTypes.") $filter ORDER BY createdAt DESC", $params);
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

    checkMyUser($userId, $request);
    checkRequired($body, 'type');
    checkRequired($body, 'category');
    checkRequired($body, 'title');

    $body['user'] = $userId;
    $postId = $access->createObject("posts", $body, "post");
    if ($postId !== FALSE) {
        $access->data['post']['user'] = $userId;
        $response = $response->withStatus(201);
        
        $access->updateLastPostDate($userId);
        
        // sharing
        if ($body['type'] == PostTypeShare) {
            $sharedPostId = $body['sharedPost'];
            
            // notification to original user
            $sharedPost = $access->getObject("posts", $sharedPostId, "user");
            if ($sharedPost) {
                $access->createNotification($userId, array($sharedPost['user']), $postId, NotificationTypeShare);
            }

            // mark original post as featured
            $stmt = $this->db->prepare("UPDATE postStats SET featured = TRUE WHERE post = ?");
            $stmt->bindValue(1, $sharedPostId);
            $stmt->execute();
        }
        
        if (empty($body['stats'])) {
            $statsId = $access->createObject("postStats", array('post' => $postId), "postStats");
            if ($statsId !== FALSE) {
                $access->data['postStats']['post'] = $postId;
                $stmt = $this->db->prepare("UPDATE posts SET stats = ? WHERE objectId = ?");
                $stmt->bindParam(1, $statsId);
                $stmt->bindParam(2, $postId);
                if ($stmt->execute()) {
                    $access->data['post']['stats'] = $statsId;
                    if ($stmt->rowCount() == 0) {
                        throw new APIException("Could not add statistics to post.", 500, "InternalServerError");
                    }
                }
            }
        }

    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// get user
$app->get('/users/{id}', function (Request $request, Response $response) {
    $params = $request->getQueryParams();
    $userId = $request->getAttribute('id');
    $access = new DataBaseAccess($this->db);

    $user = $access->addObject("users", "user", $userId, FULL_USER_FIELDS);
    if ($user !== FALSE) {
        $filter = $access->getPostsFilter($params, "AND");
        $stmt = $access->prepareMainStatement("SELECT ".MIN_POST_FIELDS." FROM posts WHERE user = ? AND type IN (".NormalPostTypes.") $filter ORDER BY createdAt DESC", $params);
        $stmt->bindValue(1, $userId);
        $posts = $access->addObjects($stmt, "posts");
        if ($posts !== FALSE) {
            $access->addSubObjects($posts, "stats", "postStats");
        }
    }

    $response = $response->withJson($access->data);
    return $response;
});

// update user
$app->put('/users/{id}', function (Request $request, Response $response) {
    $userId = $request->getAttribute('id');
    $body = $request->getParsedBody();
    $access = new DataBaseAccess($this->db);

    checkMyUser($userId, $request);

    if (isset($body['bcryptPassword'])) {
        throw new APIException("You don't have the permission for this.", 403, "Forbidden");
    }
    if (isset($body['username'])) {
        checkNewUsername($body['username']);
    }
    if (isset($body['password'])) {
        checkNewPassword($body['password']);
        $body['bcryptPassword'] = password_hash($body['password'], PASSWORD_DEFAULT);
        unset($body['password']);
    }

    $access->updateObject("users", $userId, $body);

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

// reset password
$app->post('/resetPassword', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $access = new DataBaseAccess($this->db);
    
    if (isset($body['userId'])) {
        $userId = $body['userId'];
        $password = "new".mt_rand(1000, 9999);
        $user['bcryptPassword'] = password_hash($password, PASSWORD_DEFAULT);
        $access->updateObject("users", $userId, $user);
        $access->data['password'] = $password;
    }

    $response = $response->withJson($access->data);
    return $response;
})->add(new AuthMiddleware());

/* ============ Files ============ */

// save file
$app->post('/files/{name}', function (Request $request, Response $response) {
    $name = basename($request->getAttribute('name'));
    $body = $request->getBody();
    $settings = $this->get('settings')['lowres'];
    $data = array();

    if ($body->getSize() > 1 * 1024 * 1024) {
        throw new APIException("The uploaded file is too large.", 403, "FileTooLarge");
    } else {
        $uniqueName = "lrc-".bin2hex(openssl_random_pseudo_bytes(16))."-".$name;

        file_put_contents($settings['filespath']."/".$uniqueName, $body);

        $data['name'] = $uniqueName;
        $data['url'] = $settings['filesurl']."/".$uniqueName;
    }

    $response = $response->withJson($data);
    return $response;
})->add(new AuthMiddleware());

/* ============ Sessions ============ */

// sign up
$app->post('/users', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $username = $body['username'];
    $password = $body['password'];
    $settings = $this->get('settings')['lowres'];
    $access = new DataBaseAccess($this->db);

    checkNewUsername($username);
    checkNewPassword($password);

    $sessionToken = $access->unique_id(25);
    $body['bcryptPassword'] = password_hash($password, PASSWORD_DEFAULT);
    $body['sessionToken'] = $sessionToken;

    unset($body['password']);

    try {
        $userId = $access->createObject("users", $body, "user");
    } catch (PDOException $e) {
        if ($e->getCode() == "23000") {
            throw new APIException("The username is already used.", 403, "ExistingUsername");
        } else {
            throw $e;
        }
    }

    if ($userId !== FALSE) {
        // follow admin        
        $followsObject = array('user' => $userId, 'followsUser' => $settings['admin']);
        $followId = $access->createObject("follows", $followsObject, "follow");
        if ($followId !== FALSE) {
            $access->data['follow']['followsUser'] = $userId;
        }

        $response = $response->withStatus(201);
        $access->data['user']['sessionToken'] = $sessionToken;
    }

    $response = $response->withJson($access->data);
    return $response;
});

// log in
$app->post('/login', function (Request $request, Response $response) {
    $body = $request->getParsedBody();
    $username = $body['username'];
    $password = $body['password'];
    $access = new DataBaseAccess($this->db);

    checkRequired($body, 'username');
    checkRequired($body, 'password');

    $stmt = $this->db->prepare("SELECT * FROM users WHERE username = ?");
    $stmt->bindParam(1, $username);
    if ($stmt->execute()) {
        $user = $stmt->fetch();
        if ($user == NULL) {
            throw new APIException("The username or password is invalid.", 403, "InvalidLogin");
        } else {
            $valid = password_verify($password, $user['bcryptPassword']);
            if ($valid) {
                unset($user['bcryptPassword']);

                if (empty($user['sessionToken'])) {
                    $sessionToken = $access->unique_id(25);
                    $stmt = $this->db->prepare("UPDATE users SET sessionToken = ? WHERE objectId = ?");
                    $stmt->bindParam(1, $sessionToken);
                    $stmt->bindParam(2, $user['objectId']);
                    if ($stmt->execute()) {
                        $user['sessionToken'] = $sessionToken;
                    }
                }

                $access->data['user'] = $user;
            } else {
                throw new APIException("The username or password is invalid.", 403, "InvalidLogin");
            }
        }
    }
    $response = $response->withJson($access->data);
    return $response;
});

// log out
$app->post('/logout', function (Request $request, Response $response) {
    $currentUser = $request->getAttribute('currentUser');
    $access = new DataBaseAccess($this->db);

    $stmt = $this->db->prepare("UPDATE users SET sessionToken = NULL WHERE objectId = ?");
    $stmt->bindValue(1, $currentUser);
    if ($stmt->execute()) {
        $access->data['success'] = TRUE;
    }

    $response = $response->withJson($access->data);
    return $response;

})->add(new AuthMiddleware());

$app->run();
?>