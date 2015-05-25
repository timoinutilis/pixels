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

extern NSString *const CurrentUserChangeNotification;
extern NSString *const FollowsChangeNotification;

@interface CommunityModel : NSObject

@property (readonly) NSMutableArray *follows;

+ (CommunityModel *)sharedInstance;
+ (void)registerSubclasses;

- (void)onLoggedIn;
- (void)onLoggedOut;
- (void)updateCurrentUser;
- (void)onPostedWithDate:(NSDate *)date;

- (void)followUser:(LCCUser *)user;
- (void)unfollowUser:(LCCUser *)user;
- (LCCFollow *)followWithUser:(LCCUser *)user;
- (BOOL)canFollowOrUnfollow:(LCCUser *)user;
- (NSArray *)arrayWithFollowedUser;

@end
