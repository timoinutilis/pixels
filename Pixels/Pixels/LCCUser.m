//
//  LCCUser.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "LCCUser.h"

@implementation LCCUser

@dynamic about;
@dynamic lastPostDate;

- (BOOL)isMe
{
    if ([PFUser currentUser])
    {
        return [self.objectId isEqualToString:[PFUser currentUser].objectId];
    }
    return NO;
}

@end
