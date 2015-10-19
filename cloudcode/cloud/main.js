var Post = Parse.Object.extend("Post");
var Program = Parse.Object.extend("Program");
var Comment = Parse.Object.extend("Comment");
var Count = Parse.Object.extend("Count");
var PostStats = Parse.Object.extend("PostStats");


function getAppVersion(request) {
  var promise = new Parse.Promise();
  if (request.installationId) {
    var query = new Parse.Query(Parse.Installation);
    query.equalTo('installationId', request.installationId);
    query.first({'useMasterKey': true}).then(function(result) {
      var appVersion = parseInt(result.get('appVersion'));
      promise.resolve(appVersion);
    }, function(error) {
      console.error("getAppVersion: " + error.message);
      promise.resolve(0);
    });
  } else {
    promise.resolve(0);
  }
  return promise;
}

// obsolete since app version 19 (4.0)
function increasePostStats(post, key) {
  var stats = post.get("stats");
  if (!stats) {
    stats = new PostStats();
    stats.increment(key);
    post.set("stats", stats);
    return post.save();
  }
  stats.increment(key);
  return stats.save();
}

Parse.Cloud.beforeSave("Post", function(request, response) {

  // create Stats object if not there yet
  if (!request.object.get("stats")) {
    var stats = new PostStats();
    request.object.set("stats", stats);
    stats.save().then(function () {
      response.success();
    }, function (error) {
      response.error("beforeSave(Post): " + error.message);
    });
  } else {
    response.success();
  }

});

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

    // delete stats if available
    if (request.object.get("type") != 3) { // not if post is a "share"
      var stats = request.object.get("stats");
      if (stats) {
        return stats.destroy();
      }
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

  if (text.length > 100) {
    text = text.substr(0, 100) + "...";
  }

  post.fetch().then(function() {

    return getAppVersion(request).then(function(appVersion) {
      console.log("appVersion " + appVersion);
      if (appVersion != 0 && appVersion < 19) {
        return increasePostStats(post, "numComments");
      }
    });

  }).then(function() {

    if (user) {

      return user.fetch().then(function() {
        
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
          commentsQuery.exists("user");

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
      });
    
    }

  }, function(error) {

    // there was some error.
    console.error("afterSave(Comment): " + error.message);

  });

});


Parse.Cloud.afterSave("Count", function(request) {

  getAppVersion(request).then(function(appVersion) {

    console.log("appVersion " + appVersion);
    if (appVersion != 0 && appVersion < 19) {

      var post = request.object.get('post');
      var type = request.object.get('type');

      var incKey;
      if (type == 1) {
        incKey = "numLikes";
      } else if (type == 2) {
        incKey = "numDownloads";
      }

      post.fetch().then(function() {

        return increasePostStats(post, incKey);

      });
    }
  });

});
