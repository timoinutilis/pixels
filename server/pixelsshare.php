<?php
// send pixel program to timo@inutilis.com

header('Content-type: application/json');

$result = array();

if (   empty($_REQUEST['secret'])
	|| empty($_REQUEST['author'])
	|| !isset($_REQUEST['mail'])
	|| empty($_REQUEST['title'])
	|| empty($_REQUEST['description'])
	|| empty($_REQUEST['source_code']) )
{
	$result["error"] = "Missing parameters";
}
else
{
	$secret = $_REQUEST['secret'];
	$author = $_REQUEST['author'];
	$mail = filter_var($_REQUEST['mail'], FILTER_SANITIZE_EMAIL);
	$title = $_REQUEST['title'];
	$description = $_REQUEST['description'];
	$source_code = $_REQUEST['source_code'];

	if ($secret != "916486295")
	{
		$result["error"] = "Wrong secret";
	}
	else
	{
		$subject = "Shared: {$title}";
		$message = "Author: {$author}\r\nTitle: {$title}\r\n\r\nDescription:\r\n{$description}\r\n\r\n----------------------------\r\n{$source_code}";
		$headers = "From: Pixels <mailer@kundenserver.de>\r\n";
		if (!empty($mail))
		{
			$headers .= "Reply-To: {$mail}\r\n";
		}

		$subject = mb_encode_mimeheader($subject, "UTF-8", "Q");

		if (!mail("timo@inutilis.com", $subject, $message, $headers))
		{
			$result["error"] = "Sending mail failed";
		}
		else
		{
			$result["result"] = "OK";
		}
	}
}

echo json_encode($result);

?>