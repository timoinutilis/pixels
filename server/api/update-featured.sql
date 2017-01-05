UPDATE postStats
SET featured=TRUE
WHERE post IN
(
   	SELECT sharedPost
    FROM posts
	WHERE sharedPost IS NOT NULL
);