//
//  LCCComment.h
//  Pixels
//
//  Created by Timo Kloss on 22/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

@class LCCUser, LCCPost;

@interface LCCComment : PFObject<PFSubclassing>

@property (retain) LCCUser *user;
@property (retain) LCCPost *post;
@property (retain) NSString *text;

@end
