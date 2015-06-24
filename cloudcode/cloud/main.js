var Post = Parse.Object.extend("Post");
var Program = Parse.Object.extend("Program");
var Comment = Parse.Object.extend("Comment");
var Count = Parse.Object.extend("Count");


Parse.Cloud.beforeDelete("Post", function(request, response) {

  var postsQuery = new Parse.Query(Post);
  postsQuery.equalTo("sharedPost", request.object);

  postsQuery.find().then(function(results) {

    // delete share posts
    return Parse.Object.destroyAll(results);

  }).then(function() {

    var commentsQuery = new Parse.Query(Comment);
    commentsQuery.equalTo("post", request.object);
    return commentsQuery.find();

  }).then(function(results) {

    // delete comments
    return Parse.Object.destroyAll(results);

  }).then(function() {

    var countsQuery = new Parse.Query(Count);
    countsQuery.equalTo("post", request.object);
    return countsQuery.find();

  }).then(function(results) {

    // delete counts
    return Parse.Object.destroyAll(results);

  }).then(function() {

    // delete program if available
    var program = request.object.get("program");
    if (program) {
      return program.destroy();
    }

  }).then(function() {

    response.success();

  }, function(error) {

    // there was some error.
    response.error("beforeDelete(Post): " + error.message);

  });

});
