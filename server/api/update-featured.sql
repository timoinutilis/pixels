UPDATE posts
SET featured=TRUE
WHERE objectId IN
(
    SELECT sharedPost FROM
    (
    	SELECT sharedPost
        FROM posts
        WHERE sharedPost IS NOT NULL
    ) AS temp
);