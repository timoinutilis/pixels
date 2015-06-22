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

extern NSString *const CurrentUserChangeNotification;
extern NSString *const FollowsChangeNotification;
extern NSString *const PostDeleteNotification;

extern NSString *const UserDefaultsLogInKey;

@interface CommunityModel : NSObject

@property (readonly) NSMutableArray *follows;

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
- (void)countPost:(LCCPost *)post type:(LCCCountType)type;
- (void)fetchCountForPost:(LCCPost *)post type:(LCCCountType)type block:(void (^)(NSArray *users))block;
- (BOOL)isCurrentUserInArray:(NSArray *)array;

@end
