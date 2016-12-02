<?php

if (empty($_GET['file']))
{
	die();
}
$filename = $_GET['file'];

if ($_SERVER['SERVER_NAME'] == "localhost") {
    $host = "localhost";
    $port = "8889";
    $user = "root";
    $pass = "root";
    $dbname = "lowres";
} else {
    $host = "db645859868.db.1and1.com";
    $port = "3306";
    $user = "dbo645859868";
    $pass = "lowres.82";
    $dbname = "db645859868";
}

$pdo = new PDO("mysql:host=" . $host . ";port=" . $port . ";dbname=" . $dbname . ';charset=utf8mb4', $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

$dump = file_get_contents($filename);
if ($dump !== FALSE) {
	
	$lines = explode("\n", $dump);
    $currSQL = "";
    $count = 0;
	foreach ($lines as $line) {
        if ($line != "") {
            $start = substr($line, 0, 2);
	       	if ($start != "--" && $start != "/*") {
                $currSQL .= $line;
                if (substr($currSQL, -1) == ";") {
                    //execute
                    $count += $pdo->exec($currSQL);
                    $currSQL = "";
                }
            }
        }
	}
    echo "$count rows affected";

} else {
	echo "file not found";
}

?>