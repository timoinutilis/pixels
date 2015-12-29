//
//  LCCUser.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

extern NSString *const LowResNewsUserIDKey;

@interface LCCUser : PFUser<PFSubclassing>

@property (retain) NSString *about;
@property (retain) NSDate *lastPostDate;
@property (retain) NSDate *notificationsOpenedDate;

- (BOOL)isMe;
- (BOOL)isNewsUser;

@end
