<?php

require dirname(__FILE__) . '/autoload.php';

use Parse\ParseClient;
use Parse\ParseQuery;
use Parse\ParseException;

$objectId = $_GET["id"];

header('Content-Type: text/plain');

ParseClient::initialize('JjXUGeQFrN79s4TcIunronsM13ehsBy0Pa1FLIUA', 'YlUL5qFSyRFVS0rFLdIHUQjNuTzHi294XDy7G9Em', 'g8mqpMyqSxN78OUfwmT7gwPLqOIQ4VqG4N0YWAg3');

try {
	$query = new ParseQuery("Program");
	$program = $query->get($objectId);
	echo $program->get("sourceCode");
} catch (ParseException $ex) {
	echo "Error loading source code.";
}

?>