var Post = Parse.Object.extend("Post");
var Program = Parse.Object.extend("Program");
var Comment = Parse.Object.extend("Comment");
var Count = Parse.Object.extend("Count");
var PostStats = Parse.Object.extend("PostStats");
var Notification = Parse.Object.extend("Notification");

var NotificationTypeComment = 0;
var NotificationTypeLike = 1;
var NotificationTypeShare = 2;
var NotificationTypeFollow = 3;

var CountTypeLike = 1;
var CountTypeDownload = 2;

var PostTypeProgram = 1;
var PostTypeStatus = 2;
var PostTypeShare = 3;

// **** Migration ****

var MigrationMessage = "Please update LowRes Coder to version 6.0 or higher!";

Parse.Cloud.beforeSave(Parse.User, function(request, response) {
  response.error(MigrationMessage);
});

Parse.Cloud.beforeSave("Comment", function(request, response) {
  response.error(MigrationMessage);
});

/*Parse.Cloud.beforeSave("Post", function(request, response) {
  response.error(MigrationMessage);
});*/

// **** End Migration ****


Parse.Cloud.afterSave("Post", function(request) {

  var user = request.object.get('user');
  var type = request.object.get('type');
  var sharedPost = request.object.get('sharedPost');

  if (type == PostTypeShare) {

    sharedPost.fetch().then(function() {

      var notification = new Notification();
      notification.set("type", NotificationTypeShare);
      notification.set("sender", user);
      notification.set("recipient", sharedPost.get('user'));
      notification.set("post", sharedPost);
      notification.save();

    }, function(error) {

      // there was some error.
      console.error("afterSave(Post): " + error.message);

    });

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

            var notifications = [];
            for (var i = 0; i < commenters.length; i++) {
              var notification = new Notification();
              notification.set("type", NotificationTypeComment);
              notification.set("sender", user);
              notification.set("recipient", commenters[i]);
              notification.set("post", post);
              notifications.push(notification);
            }

            return Parse.Object.saveAll(notifications).then(function() {
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

          });

        } else {
          // commented on other post, notify post owner

          var notification = new Notification();
          notification.set("type", NotificationTypeComment);
          notification.set("sender", user);
          notification.set("recipient", postOwner);
          notification.set("post", post);

          return notification.save().then(function() {

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

    var type = request.object.get('type');
    var user = request.object.get('user');
    var post = request.object.get('post');

    if (type == CountTypeLike) {

      post.fetch().then(function() {

        var notification = new Notification();
        notification.set("type", NotificationTypeLike);
        notification.set("sender", user);
        notification.set("recipient", post.get('user'));
        notification.set("post", post);
        return notification.save();

      }, function(error) {

        // there was some error.
        console.error("afterSave(Count): " + error.message);

      });
      
    }

});


Parse.Cloud.afterSave("Follow", function(request) {

  var user = request.object.get('user');
  var followsUser = request.object.get('followsUser');

  var notification = new Notification();
  notification.set("type", NotificationTypeFollow);
  notification.set("sender", user);
  notification.set("recipient", followsUser);
  notification.save();

});
