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

	function setSQLError($stmt) {
		$this->setError("SQL", $stmt->errorInfo()[2]);
	}

	function getPostsFilter($queryParams, $word) {
		$filter = "";
	    if (!empty($queryParams['category'])) {
	        $category = intval($queryParams['category']);
	        $filter = " category = $category";
	    }
	    if ($filter != "") {
	    	$filter = $word.$filter;
	    }
	    return $filter;
	}

	function addObject($tableName, $dataName, $id, $fields ="*") {
	    if ($fields != "*") {
	    	$fields = "objectId, updatedAt, createdAt, ".$fields;
	    }

	    $sqlText = "SELECT $fields FROM $tableName WHERE objectId = ?";
	    $stmt = $this->db->prepare($sqlText);
	    $stmt->bindValue(1, $id);
	    if ($stmt->execute()) {
	    	$object = $stmt->fetch();
	        $this->data[$dataName] = $object;
	        return $object;
	    } else {
	        $this->setSQLError($stmt);
	    }
	    return FALSE;
	}

	function prepareMainStatement($tableName, $queryParams, $fields ="*", $options = NULL) {
	    $limit = !empty($queryParams['limit']) ? intval($queryParams['limit']) : 0;
	    $offset = !empty($queryParams['offset']) ? intval($queryParams['offset']) : 0;
	    if ($fields != "*") {
	    	$fields = "objectId, updatedAt, createdAt, ".$fields;
	    }
	    $sqlText = "SELECT $fields FROM $tableName";
	    if (!empty($options)) {
	    	$sqlText .= " $options";
	    }
	    if ($limit > 0) {
	        $sqlText .= " LIMIT $offset, $limit";
	    }
	    return $this->db->prepare($sqlText);
	}

    function addObjects($stmt, $dataName) {
	    if ($stmt->execute()) {
	    	$objects = $stmt->fetchAll();
	        $this->data[$dataName] = $objects;
	        return $objects;
	    } else {
	        $this->setSQLError($stmt);
	    }
	    return FALSE;
    }

	function addSubObjects($mainObjects, $idColumnName, $sourceTableName, $fields ="*") {
		if (empty($mainObjects)) {
			$this->data[$sourceTableName] = array();
			return TRUE;
		}
	    if ($fields != "*") {
	    	$fields = "objectId, updatedAt, createdAt, ".$fields;
	    }

        $ids = array();
        foreach ($mainObjects as $mainObject) {
            $id = $mainObject[$idColumnName];
            $ids[$id] = "'$id'";
        }
        $idsString = implode(",", $ids);
        $stmt = $this->db->prepare("SELECT $fields FROM $sourceTableName WHERE objectId IN ($idsString)");
        if ($stmt->execute()) {
            $this->data[$sourceTableName] = $stmt->fetchAll();
            return TRUE;
        } else {
	        $this->setSQLError($stmt);
        }
        return FALSE;
	}

	function addFollowUsers($userId, $getFollowers) {
		if ($getFollowers) {
			// followers
			$options = "ON f.user = u.objectId WHERE followsUser = ?";
		} else {
			// following
			$options = "ON f.followsUser = u.objectId WHERE user = ?";
		}
	    $stmt = $this->db->prepare("SELECT u.objectId, u.updatedAt, u.createdAt, u.username, u.lastPostDate FROM follows f JOIN users u $options ORDER BY createdAt DESC");
	    $stmt->bindValue(1, $userId);
	    if ($stmt->execute()) {
	        $this->data['users'] = $stmt->fetchAll();
	        return TRUE;
	    } else {
	        $this->setSQLError($stmt);
	    }
	    return FALSE;
	}

	function getFollowedUserIds($userId) {
		$stmt = $this->db->prepare("SELECT followsUser FROM follows WHERE user = ?");
	    $stmt->bindValue(1, $userId);
	    if ($stmt->execute()) {
	    	$ids = array();
	    	while ($object = $stmt->fetch()) {
	    		$ids[] = $object['followsUser'];
	    	}
	    	return $ids;
	    } else {
	        $this->setSQLError($stmt);
	    }
	    return FALSE;
	}

	function createObject($tableName, $body, $dataName = NULL) {
		$id = $this->uniqid_base36();
		$columns = array("objectId", "createdAt");
		$values = array("'$id'", "NOW()");
		foreach ($body as $key => $value) {
			$columns[] = $key;
			$values[] = ":".$key;
		}
		$columnsString = implode($columns, ", ");
		$valuesString = implode($values, ", ");
	    $stmt = $this->db->prepare("INSERT INTO $tableName ($columnsString) VALUES ($valuesString)");
	    foreach ($body as $key => $value) {
		    $stmt->bindValue(":".$key, $value);
		}
	    if ($stmt->execute()) {
	    	$createdAt = NULL;
		    $stmt = $this->db->prepare("SELECT createdAt FROM $tableName WHERE objectId = ?");
		    $stmt->bindValue(1, $id);
		    if ($stmt->execute()) {
		    	$object = $stmt->fetch();
   		   		$createdAt = $object['createdAt'];
 			    if (!empty($dataName)) {
   			    	$this->data[$dataName] = array('objectId' => $id, 'createdAt' => $createdAt);
			    } else {
			    	$this->data['objectId'] = $id;
			    	$this->data['createdAt'] = $createdAt;
			    }
		    }		    
	        return $id;
	    } else {
	        $this->setSQLError($stmt);
	    }
	    return FALSE;
	}

	function increasePostStats($postId, $numDownloads, $numComments, $numLikes) {
		$stmt = $this->db->prepare("UPDATE postStats SET numDownloads = numDownloads+$numDownloads, numComments = numComments+$numComments, numLikes = numLikes+$numLikes WHERE post = ?");
		$stmt->bindValue(1, $postId);
		if ($stmt->execute()) {
			// add postStats to data
		} else {
			$this->setSQLError($stmt);
		}
		return FALSE;
	}

	function userLikesPost($userId, $postId) {
	    $stmt = $this->db->prepare("SELECT objectId FROM likes WHERE user = ? AND post = ?");
	    $stmt->bindParam(1, $userId);
	    $stmt->bindParam(2, $postId);
	    if ($stmt->execute()) {
	    	if ($stmt->fetch()) {
	    		return TRUE;
	       	}
	    } else {
			$this->setSQLError($stmt);
		}
		return FALSE;
	}

	function uniqid_base36() {
    	$s = uniqid();
        return base_convert($s, 16, 36);
    }

}
?> 