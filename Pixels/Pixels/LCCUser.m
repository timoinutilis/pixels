//
//  LCCUser.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "LCCUser.h"
#import "CommunityModel.h"

NSString *const LowResNewsUserIDKey = @"LowResNewsUserID";

@implementation LCCUser

@dynamic username;
@dynamic password;
@dynamic sessionToken;
@dynamic about;
@dynamic lastPostDate;
@dynamic notificationsOpenedDate;

- (BOOL)isMe
{
    LCCUser *currentUser = [CommunityModel sharedInstance].currentUser;
    return currentUser && [currentUser.objectId isEqualToString:self.objectId];
}

- (BOOL)isNewsUser
{
    NSString *newsUserID = [[NSBundle mainBundle] objectForInfoDictionaryKey:LowResNewsUserIDKey];
    return ([self.objectId isEqualToString:newsUserID]);
}

@end
