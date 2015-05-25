//
//  LCCFollow.h
//  Pixels
//
//  Created by Timo Kloss on 25/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

@class LCCUser;

@interface LCCFollow : PFObject<PFSubclassing>

@property (retain) LCCUser *user;
@property (retain) LCCUser *followsUser;

@end
