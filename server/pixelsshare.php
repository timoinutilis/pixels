<?php
// send pixel program to timo@inutilis.com

header('Content-type: application/json');

$result = array();

if (   empty($_REQUEST['secret'])
	|| empty($_REQUEST['author'])
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
		$message = "Author: {$author}\r\nTitle: {$title}\r\n\r\nDescription:\r\n{$description}\r\n\r\nSource Code:\r\n{$source_code}";
		$headers = "From: Pixels <mailer@kundenserver.de>\r\n";

		$subject = mb_encode_mimeheader($subject, "UTF-8", "Q");
		$message = quoted_printable_encode($message);

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