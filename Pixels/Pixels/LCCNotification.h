//
//  LCCNotification.h
//  Pixels
//
//  Created by Timo Kloss on 25/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

typedef NS_ENUM(NSInteger, LCCNotificationType) {
    LCCNotificationTypeComment,
    LCCNotificationTypeLike,
    LCCNotificationTypeShare,
    LCCNotificationTypeFollow
};

@class LCCUser, LCCPost;

@interface LCCNotification : PFObject<PFSubclassing>

@property (nonatomic) LCCNotificationType type;
@property (nonatomic, retain) LCCUser *sender;
@property (nonatomic, retain) LCCUser *recipient;
@property (nonatomic, retain) LCCPost *post;

@end
