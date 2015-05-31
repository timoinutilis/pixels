//
//  LCCCount.h
//  Pixels
//
//  Created by Timo Kloss on 31/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

typedef NS_ENUM(NSInteger, LCCCountType) {
    LCCCountTypeLike = 1,
    LCCCountTypeDownload = 2
};

@class LCCUser, LCCPost;

@interface LCCCount : PFObject<PFSubclassing>

@property LCCCountType type;
@property (retain) LCCUser *user;
@property (retain) LCCPost *post;

@end
