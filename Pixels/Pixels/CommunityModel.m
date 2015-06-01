//
//  CommunityModel.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommunityModel.h"

NSString *const CurrentUserChangeNotification = @"CurrentUserChangeNotification";
NSString *const FollowsChangeNotification = @"FollowsChangeNotification";

NSString *const UserDefaultsLogInKey = @"UserDefaultsLogIn";
NSString *const LowResNewsUserIDKey = @"LowResNewsUserID";

@implementation CommunityModel

+ (CommunityModel *)sharedInstance
{
    static CommunityModel *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)registerSubclasses
{
    [LCCUser registerSubclass];
    [LCCPost registerSubclass];
    [LCCProgram registerSubclass];
    [LCCComment registerSubclass];
    [LCCFollow registerSubclass];
    [LCCCount registerSubclass];
}

- (void)onLoggedIn
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
    [self updateCurrentUser];
}

- (void)onLoggedOut
{
    [self.follows removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
    [self updateCurrentUser];
}

- (void)onUserDataChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
}

- (void)updateCurrentUser
{
    if ([PFUser currentUser])
    {
        PFQuery *query = [PFQuery queryWithClassName:[LCCFollow parseClassName]];
        [query whereKey:@"user" equalTo:[PFUser currentUser]];
        [query includeKey:@"followsUser"];
        [query orderByDescending:@"lastPostDate"];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            if (objects)
            {
                _follows = [NSMutableArray arrayWithArray:objects];
                [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
            }
            else
            {
                NSLog(@"Error: %@", error.description);
            }
            
        }];
    }
    else
    {
        _follows = [NSMutableArray array];
        
        LCCFollow *defaultFollow = [LCCFollow object];
        NSString *newsUserID = [[NSBundle mainBundle] objectForInfoDictionaryKey:LowResNewsUserIDKey];
        defaultFollow.followsUser = [LCCUser objectWithoutDataWithObjectId:newsUserID];
        
        [defaultFollow.followsUser fetchInBackgroundWithBlock:^(PFObject *object,  NSError *error) {
            
            if (object)
            {
                [_follows addObject:defaultFollow];
                [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
            }
            else
            {
                NSLog(@"Error: %@", error.description);
                [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
            }
            
        }];
    }
}

- (void)onPostedWithDate:(NSDate *)date
{
    LCCUser *user = (LCCUser *)[PFUser currentUser];
    user.lastPostDate = date;
    [user saveInBackground];
}

- (void)followUser:(LCCUser *)user
{
    LCCFollow *follow = [LCCFollow object];
    follow.user = (LCCUser *)[PFUser currentUser];
    follow.followsUser = user;
    [follow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            [self.follows insertObject:follow atIndex:0];
            [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
        }
        else
        {
            NSLog(@"Error: %@", error.description);
        }
    }];
}

- (void)unfollowUser:(LCCUser *)user
{
    LCCFollow *follow = [self followWithUser:user];
    if (follow)
    {
        [follow deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
            {
                [self.follows removeObject:follow];
                [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
            }
            else
            {
                NSLog(@"Error: %@", error.description);
            }
        }];
    }
}

- (LCCFollow *)followWithUser:(LCCUser *)user
{
    for (LCCFollow *follow in self.follows)
    {
        if ([follow.followsUser.objectId isEqualToString:user.objectId])
        {
            return follow;
        }
    }
    return nil;
}

- (BOOL)canFollowOrUnfollow:(LCCUser *)user
{
    LCCUser *currentUser = (LCCUser *)[PFUser currentUser];
    if (currentUser)
    {
        NSString *newsUserID = [[NSBundle mainBundle] objectForInfoDictionaryKey:LowResNewsUserIDKey];
        return (![user isMe] && ![user.objectId isEqualToString:newsUserID]);
    }
    return NO;
}

- (NSArray *)arrayWithFollowedUsers
{
    NSMutableArray *array = [NSMutableArray array];
    for (LCCFollow *follow in self.follows)
    {
        [array addObject:follow.followsUser];
    }
    return array;
}

- (void)countPost:(LCCPost *)post type:(LCCCountType)type
{
    if (![post.user isMe])
    {
        LCCCount *count = [LCCCount object];
        count.post = post;
        count.user = (LCCUser *)[PFUser currentUser];
        count.type = type;
        
        [count saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded && error)
            {
                NSLog(@"Error: %@", error.description);
            }
        }];

    }
}

- (void)fetchCountForPost:(LCCPost *)post type:(LCCCountType)type block:(void (^)(NSArray *users))block
{
    PFQuery *query = [PFQuery queryWithClassName:[LCCCount parseClassName]];
    [query whereKey:@"post" equalTo:post];
    [query whereKey:@"type" equalTo:@(type)];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects)
        {
            NSMutableArray *users = [NSMutableArray arrayWithCapacity:objects.count];
            for (LCCCount *count in objects)
            {
                [users addObject:count.user];
            }
            block(users);
        }
        else if (error)
        {
            NSLog(@"Error: %@", error.description);
            block(nil);
        }
        
    }];
}

- (BOOL)isCurrentUserInArray:(NSArray *)array
{
    NSString *currentUserId = [PFUser currentUser].objectId;
    for (LCCUser *user in array)
    {
        if ([user.objectId isEqualToString:currentUserId])
        {
            return YES;
        }
    }
    return NO;
}

@end
