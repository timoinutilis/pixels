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
NSString *const FollowsLoadNotification = @"FollowsLoadNotification";
NSString *const FollowsChangeNotification = @"FollowsChangeNotification";
NSString *const PostDeleteNotification = @"PostDeleteNotification";
NSString *const PostStatsChangeNotification = @"PostStatsChangeNotification";
NSString *const NotificationsUpdateNotification = @"NotificationsUpdateNotification";
NSString *const NotificationsNumChangeNotification = @"NotificationsNumChangeNotification";

NSString *const UserDefaultsLogInKey = @"UserDefaultsLogIn";
NSString *const HTTPHeaderSessionTokenKey = @"X-LowResCoder-Session-Token";

@interface CommunityModel()
@property (nonatomic) AFHTTPSessionManager *sessionManager;
@end

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

- (instancetype)init
{
    if (self = [super init])
    {
        NSString *url = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LowResAPIURL"];
        NSAssert(url, @"LowResAPIURL not defined in info.plist");
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:url]];
        
        [LCCUser registerAPIClass];
        [LCCPost registerAPIClass];
        [LCCComment registerAPIClass];
        [LCCPostStats registerAPIClass];
        [LCCNotification registerAPIClass];
    }
    return self;
}

- (void)signUpWithUser:(LCCUser *)user completion:(LCCResultBlock)completion
{
    NSDictionary *params = [user dirtyDictionary];
    
    [self.sessionManager POST:@"users" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [self onLoggedInWithUser:[[LCCUser alloc] initWithDictionary:responseObject]];
        completion(YES, nil);
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        completion(NO, error);
        
    }];
}

- (void)logInWithUsername:(NSString *)username password:(NSString *)password completion:(LCCResultBlock)completion;
{
    NSDictionary *params = @{@"username":username, @"password":password};
    
    [self.sessionManager POST:@"login" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [self onLoggedInWithUser:[[LCCUser alloc] initWithDictionary:responseObject[@"user"]]];
        completion(YES, nil);
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        completion(NO, error);
    }];

}

- (void)logOutWithCompletion:(LCCResultBlock)completion
{
    [self.sessionManager POST:@"logout" parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [self onLoggedOut];
        completion(YES, nil);
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        completion(NO, error);
        
    }];
}

- (void)onLoggedInWithUser:(LCCUser *)user
{
    _currentUser = user;
    [self.sessionManager.requestSerializer setValue:self.currentUser.sessionToken forHTTPHeaderField:HTTPHeaderSessionTokenKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
    [self updateCurrentUser];
    [self loadNotifications];
}

- (void)onLoggedOut
{
    _currentUser = nil;
    
    [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:HTTPHeaderSessionTokenKey];
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
    if (self.currentUser)
    {
        NSString *route = [NSString stringWithFormat:@"users/%@/following", self.currentUser.objectId];
        [self.sessionManager GET:route parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            
            _follows = [LCCUser objectsFromArray:responseObject[@"users"]].mutableCopy;
            [self sortFollows];
            [[NSNotificationCenter defaultCenter] postNotificationName:FollowsLoadNotification object:self];
            
        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
            
            NSLog(@"Error: %@", error.localizedDescription);
            
        }];
    }
    else
    {
        _follows = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] postNotificationName:FollowsLoadNotification object:self];
    }
    
    // update installation
/*    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"user"] = [PFUser currentUser] ? [PFUser currentUser] : [NSNull null];
    [currentInstallation saveInBackground];*/
}

- (void)onPostedWithDate:(NSDate *)date
{/*
    LCCUser *user = (LCCUser *)[PFUser currentUser];
    if (user)
    {
        user.lastPostDate = date;
        [user saveInBackground];
    }*/
}

- (void)sortFollows
{
    NSSortDescriptor *lastPost = [NSSortDescriptor sortDescriptorWithKey:@"lastPostDate" ascending:NO];
    NSSortDescriptor *creationDate = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    [self.follows sortUsingDescriptors:@[lastPost, creationDate]];
}

- (void)followUser:(LCCUser *)user
{
    NSString *route = [NSString stringWithFormat:@"/users/%@/followers", user.objectId];
    NSDictionary *params = @{@"user":self.currentUser.objectId};
    [self.sessionManager POST:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
//        [PFQuery clearAllCachedResults];
        [self.follows insertObject:user atIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        NSLog(@"Error: %@", error.localizedDescription);
        
    }];
}

- (void)unfollowUser:(LCCUser *)user
{
    user = [self userInFollowing:user];
    if (user)
    {
        NSString *route = [NSString stringWithFormat:@"/users/%@/followers/%@", user.objectId, self.currentUser.objectId];
        [self.sessionManager DELETE:route parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

//            [PFQuery clearAllCachedResults];
            [self.follows removeObject:user];
            [[NSNotificationCenter defaultCenter] postNotificationName:FollowsChangeNotification object:self];
            
        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
            
            NSLog(@"Error: %@", error.localizedDescription);
            
        }];
    }
}

- (LCCUser *)userInFollowing:(LCCUser *)user
{
    for (LCCUser *followUser in self.follows)
    {
        if ([followUser.objectId isEqualToString:user.objectId])
        {
            return followUser;
        }
    }
    return nil;
}

- (void)likePost:(LCCPost *)post
{
    NSString *route = [NSString stringWithFormat:@"/posts/%@/likes", post.objectId];
    NSDictionary *params = @{@"user": self.currentUser.objectId};
    [self.sessionManager POST:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        LCCPostStats *stats = [[LCCPostStats alloc] initWithDictionary:responseObject[@"postStats"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:PostStatsChangeNotification object:self userInfo:@{@"stats":stats}];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        NSLog(@"Error: %@", error.localizedDescription);
        
    }];
}

- (void)countDownloadPost:(LCCPost *)post
{
    NSString *route = [NSString stringWithFormat:@"/posts/%@/downloads", post.objectId];
    [self.sessionManager POST:route parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        LCCPostStats *stats = [[LCCPostStats alloc] initWithDictionary:responseObject[@"postStats"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:PostStatsChangeNotification object:self userInfo:@{@"stats":stats}];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        NSLog(@"Error: %@", error.localizedDescription);
        
    }];
}

- (void)loadNotifications
{
    if (self.currentUser && !self.isUpdatingNotifications)
    {
        _isUpdatingNotifications = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsUpdateNotification object:self];
        
        NSString *route = [NSString stringWithFormat:@"/users/%@/notifications", self.currentUser.objectId];
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"limit"] = @(50);
        
/*        if (_notifications.count > 0)
        {
            LCCNotification *lastNotification = _notifications.firstObject;
            [query whereKey:@"createdAt" greaterThan:lastNotification.createdAt];
        }*/
        
        [self.sessionManager GET:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            
            NSArray *notifications = [LCCNotification objectsFromArray:responseObject[@"notifications"]];
            NSDictionary *usersById = [LCCUser objectsByIdFromArray:responseObject[@"users"]];
            NSDictionary *postsById = [LCCPost objectsByIdFromArray:responseObject[@"posts"]];
            if (notifications.count > 0)
            {
                // copy references to user and post objects
                for (LCCNotification *notification in notifications)
                {
                    if (notification.sender)
                    {
                        notification.senderObject = usersById[notification.sender];
                    }
                    if (notification.post)
                    {
                        notification.postObject = postsById[notification.post];
                    }
                }
                
                if (_notifications)
                {
                    [_notifications insertObjects:notifications atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, notifications.count)]];
                }
                else
                {
                    _notifications = notifications.mutableCopy;
                }
            }
            _isUpdatingNotifications = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsUpdateNotification object:self];
            [self updateNewNotifications];
            
        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
            
            _isUpdatingNotifications = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsUpdateNotification object:self];
            [self updateNewNotifications];
            
        }];
    }
}

- (void)updateNewNotifications
{
    NSInteger num = 0;
    LCCUser *user = self.currentUser;
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
{/*
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
    }*/
}

@end
