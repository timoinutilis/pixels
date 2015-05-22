//
//  CommunityModel.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommunityModel.h"

NSString *const CurrentUserChangeNotification = @"CurrentUserChangeNotification";

@implementation CommunityModel

+ (void)registerSubclasses
{
    [LCCUser registerSubclass];
    [LCCPost registerSubclass];
    [LCCComment registerSubclass];
}

@end
