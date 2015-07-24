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

Parse.Cloud.afterSave("Comment", function(request) {

  var post = request.object.get('post');
  var user = request.object.get('user');
  var text = request.object.get('text');

  if (!user) {
    // commented as guest
    return;
  }

  if (text.length > 100) {
    text = text.substr(0, 100) + "...";
  }

  post.fetch().then(function() {

    return user.fetch();

  }).then(function() {
    
    var postOwner = post.get("user");
    var postTitle = post.get("title");

    if (postTitle.length > 30) {
      postTitle = postTitle.substr(0, 30) + "...";
    }

    var alertText = user.get("username") + " commented on \"" + postTitle + "\": \"" + text + "\"";

    if (user.id == postOwner.id) {
      // commented on own post, notify all commenters of post

      var commentsQuery = new Parse.Query(Comment);
      commentsQuery.equalTo("post", post);

      return commentsQuery.find().then(function(comments) {
        var commentersObj = {};
        commentersObj[postOwner.id] = true;
        var commenters = [];
        for (var i = 0; i < comments.length; i++) {
          var commenter = comments[i].get("user");
          if (!commentersObj[commenter.id]) {
            commentersObj[commenter.id] = true;
            commenters.push(commenter);
          }
        }

        var pushQuery = new Parse.Query(Parse.Installation);
        pushQuery.containedIn('user', commenters);

        return Parse.Push.send({
          where: pushQuery,
          data: {
            alert: alertText,
            badge: "Increment",
            lrcPostId: post.id
          }
        });
      });

    } else {
      // commented on other post, notify post owner

      var pushQuery = new Parse.Query(Parse.Installation);
      pushQuery.equalTo('user', postOwner);

      return Parse.Push.send({
        where: pushQuery,
        data: {
          alert: alertText,
          badge: "Increment",
          lrcPostId: post.id
        }
      });
    }


  }).then(function() {

    // done

  }, function(error) {

    // there was some error.
    response.error("afterSave(Comment): " + error.message);

  });

});
