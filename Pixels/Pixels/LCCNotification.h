//
//  LCCNotification.h
//  Pixels
//
//  Created by Timo Kloss on 25/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "APIObject.h"

typedef NS_ENUM(NSInteger, LCCNotificationType) {
    LCCNotificationTypeComment,
    LCCNotificationTypeLike,
    LCCNotificationTypeShare,
    LCCNotificationTypeFollow
};

@interface LCCNotification : APIObject

@property (nonatomic) LCCNotificationType type;
@property (nonatomic, retain) NSString *sender;
@property (nonatomic, retain) NSString *recipient;
@property (nonatomic, retain) NSString *post;

@end
