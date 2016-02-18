//
//  CommunityModel.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommunityModel.h"
#import "AppController.h"

NSString *const CurrentUserChangeNotification = @"CurrentUserChangeNotification";
NSString *const FollowsChangeNotification = @"FollowsChangeNotification";
NSString *const PostDeleteNotification = @"PostDeleteNotification";
NSString *const PostCounterChangeNotification = @"PostCounterChangeNotification";
NSString *const UserUpdateNotification = @"UserUpdateNotification";
NSString *const NotificationsUpdateNotification = @"NotificationsUpdateNotification";
NSString *const NotificationsNumChangeNotification = @"NotificationsNumChangeNotification";

NSString *const UserDefaultsLogInKey = @"UserDefaultsLogIn";

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
    [LCCPostStats registerSubclass];
    [LCCNotification registerSubclass];
}

- (void)onLoggedIn
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
    [self updateCurrentUser];
    [self loadNotifications];
}

- (void)onLoggedOut
{
    [self.follows removeAllObjects];
    _notifications = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
    [self updateCurrentUser];
    [self updateNewNotifications];
}

- (void)onUserDataChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
}

- (void)updateCurrentUser
{
    _isUpdatingUser = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdateNotification object:self];
    
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
                [self sortFollows];
                [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
            }
            else
            {
                NSLog(@"Error: %@", error.description);
            }
            _isUpdatingUser = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdateNotification object:self];
            
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
            _isUpdatingUser = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdateNotification object:self];
            
        }];
    }
    
    // update installation
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"user"] = [PFUser currentUser] ? [PFUser currentUser] : [NSNull null];
    [currentInstallation saveInBackground];
}

- (void)onPostedWithDate:(NSDate *)date
{
    LCCUser *user = (LCCUser *)[PFUser currentUser];
    if (user)
    {
        user.lastPostDate = date;
        [user saveInBackground];
    }
}

- (void)sortFollows
{
    NSSortDescriptor *lastPost = [NSSortDescriptor sortDescriptorWithKey:@"followsUser.lastPostDate" ascending:NO];
    NSSortDescriptor *followDate = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    [self.follows sortUsingDescriptors:@[lastPost, followDate]];
}

- (void)followUser:(LCCUser *)user
{
    LCCFollow *follow = [LCCFollow object];
    follow.user = (LCCUser *)[PFUser currentUser];
    follow.followsUser = user;
    [follow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            [PFQuery clearAllCachedResults];
            [self.follows insertObject:follow atIndex:0];
            [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
            
            [PFAnalytics trackEvent:@"follow"];
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
                [PFQuery clearAllCachedResults];
                [self.follows removeObject:follow];
                [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
                
                [PFAnalytics trackEvent:@"unfollow"];
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

- (NSArray *)arrayWithFollowedUsers
{
    NSMutableArray *array = [NSMutableArray array];
    for (LCCFollow *follow in self.follows)
    {
        [array addObject:follow.followsUser];
    }
    return array;
}

- (void)countPost:(LCCPost *)post type:(StatsType)type
{
    LCCCountType countType = LCCCountTypeUndefined;
    NSString *event = nil;
    
    if (!post.stats)
    {
        post.stats = [LCCPostStats object];
    }
    
    switch (type)
    {
        case StatsTypeLike:
            [post.stats incrementKey:@"numLikes"];
            countType = LCCCountTypeLike;
            event = @"like";
            break;
        case StatsTypeDownload:
            [post.stats incrementKey:@"numDownloads"];
            countType = LCCCountTypeDownload;
            event = @"get_program";
            break;
        default:
            [NSException raise:@"InvalidType" format:@"Invalid type, comments use other method!"];
    }
    
    // UI Notification
    [[NSNotificationCenter defaultCenter] postNotificationName:PostCounterChangeNotification object:self userInfo:@{@"postId":post.objectId, @"type":@(type)}];
    
    // Save to server
    LCCCount *count = [LCCCount object];
    count.post = post;
    count.user = (LCCUser *)[PFUser currentUser];
    count.type = countType;
    
    [PFObject saveAllInBackground:@[count, post.stats] block:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (succeeded)
        {
            [self trackEvent:event forPost:post];
            [PFQuery clearAllCachedResults];
        }
        else if (error)
        {
            NSLog(@"Error: %@", error.description);
        }
        
    }];
}

- (void)trackEvent:(NSString *)name forPost:(LCCPost *)post
{
    NSDictionary *dimensions = @{@"user": [PFUser currentUser] ? @"registered" : @"guest",
                                 @"app": ([AppController sharedController].isFullVersion) ? @"full version" : @"free",
                                 @"category": [post categoryString]};
    
    [PFAnalytics trackEvent:name dimensions:dimensions];
}

- (void)loadNotifications
{
    if ([PFUser currentUser] && !self.isUpdatingNotifications)
    {
        _isUpdatingNotifications = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsUpdateNotification object:self];
        
        PFQuery *query = [PFQuery queryWithClassName:[LCCNotification parseClassName]];
        [query whereKey:@"recipient" equalTo:[PFUser currentUser]];
        [query includeKey:@"sender"];
        [query includeKey:@"post"];
        [query orderByDescending:@"createdAt"];
        if (_notifications.count > 0)
        {
            LCCNotification *lastNotification = _notifications.firstObject;
            [query whereKey:@"createdAt" greaterThan:lastNotification.createdAt];
        }
        query.cachePolicy = kPFCachePolicyNetworkOnly;
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            if (objects)
            {
                NSLog(@"read %d notifications", (int)objects.count);
                if (_notifications)
                {
                    [_notifications insertObjects:objects atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, objects.count)]];
                }
                else
                {
                    _notifications = objects.mutableCopy;
                }
            }
            _isUpdatingNotifications = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsUpdateNotification object:self];
            [self updateNewNotifications];
            
        }];
    }
}

- (void)updateNewNotifications
{
    NSInteger num = 0;
    LCCUser *user = (LCCUser *)[PFUser currentUser];
    if (user)
    {
        NSDate *date = user.notificationsOpenedDate ? user.notificationsOpenedDate : [NSDate distantPast];
        for (LCCNotification *notification in self.notifications)
        {
            if (notification.createdAt.timeIntervalSinceReferenceDate > date.timeIntervalSinceReferenceDate)
            {
                num++;
            }
        }
    }
    
    if (num != _numNewNotifications)
    {
        _numNewNotifications = num;
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsNumChangeNotification object:self];
    }
}

- (void)onOpenNotifications
{
    LCCUser *user = (LCCUser *)[PFUser currentUser];
    if (user && self.notifications.count > 0)
    {
        LCCNotification *newestNotification = self.notifications.firstObject;
        if (newestNotification.createdAt.timeIntervalSinceReferenceDate > user.notificationsOpenedDate.timeIntervalSinceReferenceDate)
        {
            user.notificationsOpenedDate = newestNotification.createdAt;
            [user saveInBackground];
            [self updateNewNotifications];
        }
    }
}

@end
