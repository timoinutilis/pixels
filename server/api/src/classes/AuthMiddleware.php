<?php
class AuthMiddleware {

    public function __invoke($request, $response, $next) {
        global $app;

        $user = NULL;
        $sessionToken = $request->getHeaderLine('X-LowResCoder-Session-Token');
        if (!empty($sessionToken)) {
            $db = $app->getContainer()['db'];
            $stmt = $db->prepare("SELECT objectId FROM users WHERE sessionToken = ?");
            $stmt->bindValue(1, $sessionToken);
            if ($stmt->execute()) {
                $user = $stmt->fetch();
                $request = $request->withAttribute('currentUser', $user['objectId']);
                //TODO check users 403 Forbidden
            }
        }

        if ($user) {
            $response = $next($request, $response);
        } else {
            $response = $response->withStatus(401)->withJson(array('error' => array('message' => "A valid session token is required.", 'type' => "Unauthorized")));
        }

        return $response;
    }
}
?>