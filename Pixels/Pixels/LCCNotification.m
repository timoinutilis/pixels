//
//  LCCNotification.m
//  Pixels
//
//  Created by Timo Kloss on 25/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "LCCNotification.h"
#import <Parse/PFObject+Subclass.h>

@implementation LCCNotification

@dynamic type;
@dynamic sender;
@dynamic recipient;
@dynamic post;

+ (NSString *)parseClassName
{
    return @"Notification";
}

@end