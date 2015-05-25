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
    [LCCComment registerSubclass];
    [LCCFollow registerSubclass];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
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
        NSString *newsUserID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LowResNewsUserID"];
        return (![user isMe] && ![user.objectId isEqualToString:newsUserID]);
    }
    return NO;
}

- (NSArray *)arrayWithFollowedUser
{
    NSMutableArray *array = [NSMutableArray array];
    for (LCCFollow *follow in self.follows)
    {
        [array addObject:follow.followsUser];
    }
    return array;
}

@end
