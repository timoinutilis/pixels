<?php
class APIException extends Exception {
	
	protected $type;

	function __construct($message, $code, $type) {
		parent::__construct($message, $code);
		$this->type = $type;
	}

	function getType() {
		return $this->type;
	}
}
?>