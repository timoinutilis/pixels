//
//  CommunityModel.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCUser.h"
#import "LCCPost.h"
#import "LCCComment.h"
#import "LCCFollow.h"
#import "LCCLike.h"
#import "LCCPostStats.h"
#import "LCCNotification.h"
#import "AFNetworking.h"

extern NSString *const CurrentUserChangeNotification;
extern NSString *const FollowsLoadNotification;
extern NSString *const FollowsChangeNotification;
extern NSString *const PostDeleteNotification;
extern NSString *const PostCounterChangeNotification;
extern NSString *const NotificationsUpdateNotification;
extern NSString *const NotificationsNumChangeNotification;

extern NSString *const UserDefaultsLogInKey;

typedef NS_ENUM(NSInteger, StatsType) {
    StatsTypeLike,
    StatsTypeDownload,
    StatsTypeComment
};

typedef void (^LCCResultBlock)(BOOL succeeded, NSError *error);

@interface CommunityModel : NSObject

@property (nonatomic, readonly) AFHTTPSessionManager *sessionManager;
@property (nonatomic, readonly) NSMutableArray<LCCUser *> *follows;
@property (nonatomic, readonly) NSMutableArray <LCCNotification *> *notifications;
@property (nonatomic, readonly) BOOL isUpdatingNotifications;
@property (nonatomic, readonly) NSInteger numNewNotifications;
@property (nonatomic, readonly) LCCUser *currentUser;

+ (CommunityModel *)sharedInstance;

- (void)signUpWithUser:(LCCUser *)user completion:(LCCResultBlock)completion;
- (void)logInWithUsername:(NSString *)username password:(NSString *)password completion:(LCCResultBlock)completion;
- (void)logOutWithCompletion:(LCCResultBlock)completion;

- (void)onUserDataChanged;
- (void)updateCurrentUser;
- (void)onPostedWithDate:(NSDate *)date;

- (void)followUser:(LCCUser *)user;
- (void)unfollowUser:(LCCUser *)user;
- (BOOL)followsUser:(LCCUser *)user;
- (NSArray *)arrayWithFollowedUsers;
- (void)countPost:(LCCPost *)post type:(StatsType)type;

- (void)loadNotifications;
- (void)onOpenNotifications;

@end
