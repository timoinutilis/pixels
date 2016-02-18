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
#import "LCCProgram.h"
#import "LCCComment.h"
#import "LCCFollow.h"
#import "LCCCount.h"
#import "LCCPostStats.h"
#import "LCCNotification.h"

extern NSString *const CurrentUserChangeNotification;
extern NSString *const FollowsChangeNotification;
extern NSString *const PostDeleteNotification;
extern NSString *const PostCounterChangeNotification;
extern NSString *const UserUpdateNotification;
extern NSString *const NotificationsUpdateNotification;
extern NSString *const NotificationsNumChangeNotification;

extern NSString *const UserDefaultsLogInKey;

typedef NS_ENUM(NSInteger, StatsType) {
    StatsTypeLike,
    StatsTypeDownload,
    StatsTypeComment
};

@interface CommunityModel : NSObject

@property (readonly) NSMutableArray *follows;
@property (readonly) BOOL isUpdatingUser;
@property (readonly) NSMutableArray <LCCNotification *> *notifications;
@property (readonly) BOOL isUpdatingNotifications;
@property (readonly, nonatomic) NSInteger numNewNotifications;

+ (CommunityModel *)sharedInstance;
+ (void)registerSubclasses;

- (void)onLoggedIn;
- (void)onLoggedOut;
- (void)onUserDataChanged;
- (void)updateCurrentUser;
- (void)onPostedWithDate:(NSDate *)date;

- (void)followUser:(LCCUser *)user;
- (void)unfollowUser:(LCCUser *)user;
- (LCCFollow *)followWithUser:(LCCUser *)user;
- (NSArray *)arrayWithFollowedUsers;
- (void)countPost:(LCCPost *)post type:(StatsType)type;
- (void)trackEvent:(NSString *)name forPost:(LCCPost *)post;

- (void)loadNotifications;
- (void)onOpenNotifications;

@end
