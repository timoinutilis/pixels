<?php
class DataBaseAccess {
	public $data;
	private $db;
	
	public function __construct($db) {
        $this->db = $db;
        $this->data = array();
    }

    function setError($type, $message) {
    	$this->data['error'] =  array('message' => $message, 'type' => $type);
	}

    function addMainObjects($tableName, $queryParams) {
	    $limit = !empty($queryParams['limit']) ? intval($queryParams['limit']) : 0;
	    $offset = !empty($queryParams['offset']) ? intval($queryParams['offset']) : 0;

	    $sqlText = "SELECT * FROM $tableName";
	    if ($limit > 0) {
	        $sqlText .= " LIMIT $offset, $limit";
	    }
	    $stmt = $this->db->prepare($sqlText);
	    if ($stmt->execute()) {
	    	$objects = $stmt->fetchAll();
	        $this->data[$tableName] = $objects;
	        return $objects;
	    } else {
	        $this->setError("SQL", $stmt->errorInfo()[2]);
	    }
	    return FALSE;
    }

	function addSubObjects($mainObjects, $idColumnName, $sourceTableName) {
        $ids = array();
        foreach ($mainObjects as $mainObject) {
            $id = $mainObject[$idColumnName];
            $ids[$id] = "'$id'";
        }
        $idsString = implode(",", $ids);
        $stmt = $this->db->prepare("SELECT * FROM $sourceTableName WHERE objectId IN ($idsString)");
        if ($stmt->execute()) {
            $this->data[$sourceTableName] = $stmt->fetchAll();
            return TRUE;
        } else {
	        $this->setError("SQL", $stmt->errorInfo()[2]);
        }
        return FALSE;
	}
}
?> 