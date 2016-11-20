<?php
class DataBaseAccess {
	public $data;
	private $db;
	
	public function __construct($db) {
        $this->db = $db;
        $this->data = array();
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
	    	if ($object) {
		        $this->data[$dataName] = $object;
		        return $object;
		    } else {
		    	throw new APIException("The object '$id' could not be found.", 404, "NotFound");
		    }
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
	    }
	    return FALSE;
	}

	function createObject($tableName, $body, $dataName) {
		$id = $this->unique_id(10);
		$columns = array("objectId", "createdAt");
		$values = array("'$id'", "NOW()");
		foreach ($body as $key => $value) {
			$columns[] = $key; // TODO make safe!
			$values[] = ":".$key; // TODO make safe!
		}
		$columnsString = implode($columns, ", ");
		$valuesString = implode($values, ", ");
	    $stmt = $this->db->prepare("INSERT INTO $tableName ($columnsString) VALUES ($valuesString)");
	    foreach ($body as $key => $value) {
		    $stmt->bindValue(":".$key, $value); // TODO make key safe!
		}
	    if ($stmt->execute()) {
	    	$createdAt = NULL;
		    $stmt = $this->db->prepare("SELECT createdAt FROM $tableName WHERE objectId = ?");
		    $stmt->bindValue(1, $id);
		    if ($stmt->execute()) {
		    	$object = $stmt->fetch();
   		   		$createdAt = $object['createdAt'];
   			    $this->data[$dataName] = array('objectId' => $id, 'createdAt' => $createdAt);
		    }		    
	        return $id;
	    }
	    return FALSE;
	}

	function updateObject($tableName, $id, $body) {
		$changes = array();
		foreach ($body as $key => $value) {
			$changes[] = "$key = :$key"; // TODO make safe!
		}
		$changesString = implode($changes, ", ");
	    $stmt = $this->db->prepare("UPDATE $tableName SET $changesString WHERE objectId = :id");
	    foreach ($body as $key => $value) {
		    $stmt->bindValue(":".$key, $value); // TODO make key safe!
		}
		$stmt->bindValue(":id", $id);
	    if ($stmt->execute()) {
	    	if ($stmt->rowCount() > 0) {
		    	$updatedAt = NULL;
			    $stmt = $this->db->prepare("SELECT updatedAt FROM $tableName WHERE objectId = ?");
			    $stmt->bindValue(1, $id);
			    if ($stmt->execute()) {
			    	$object = $stmt->fetch();
	   		   		$updatedAt = $object['updatedAt'];
			    	$this->data['updatedAt'] = $updatedAt;
			    }		    
		        return TRUE;
		    } else {
		    	throw new APIException("The object '$id' could not be found.", 404, "NotFound");
		    }
	    }
	    return FALSE;
	}

	function increasePostStats($postId, $numDownloads, $numComments, $numLikes) {
		$stmt = $this->db->prepare("UPDATE postStats SET numDownloads = numDownloads+$numDownloads, numComments = numComments+$numComments, numLikes = numLikes+$numLikes WHERE post = ?");
		$stmt->bindValue(1, $postId);
		if ($stmt->execute()) {
			if ($stmt->rowCount() > 0) {
			    $sqlText = "SELECT objectId, updatedAt, createdAt, post, numDownloads, numComments, numLikes FROM postStats WHERE post = ?";
			    $stmt = $this->db->prepare($sqlText);
			    $stmt->bindValue(1, $postId);
			    if ($stmt->execute()) {
			    	$object = $stmt->fetch();
			    	if ($object) {
				        $this->data["postStats"] = $object;
				        return $object;
				    } else {
				    	throw new APIException("Missing statistics for post '$postId'.", 500, "InternalServerError");
				    }
			    }

			} else {
				throw new APIException("Missing statistics for post '$postId'.", 500, "InternalServerError");
			}
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
	    }
		return FALSE;
	}

    function unique_id($length) {
		$characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
		$maxIndex = strlen($characters) - 1;
		$string = "";    
		for ($p = 0; $p < $length; $p++) {
			$string .= $characters[mt_rand(0, $maxIndex)];
		}
		return $string;
    }

}
?> 