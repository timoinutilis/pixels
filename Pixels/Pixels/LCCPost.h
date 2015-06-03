//
//  LCCPost.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

@class LCCUser, LCCProgram;

typedef NS_ENUM(int, LCCPostType) {
    LCCPostTypeUndefined,
    LCCPostTypeProgram,
    LCCPostTypeStatus,
    LCCPostTypeShare
};

typedef NS_ENUM(int, LCCPostCategory) {
    LCCPostCategoryUndefined,
    LCCPostCategoryStatus,
    LCCPostCategoryGame,
    LCCPostCategoryTool,
    LCCPostCategoryDemo
};

@interface LCCPost : PFObject<PFSubclassing>

@property (retain) LCCUser *user;
@property LCCPostType type;
@property LCCPostCategory category;
@property (retain) PFFile *image;
@property (retain) NSString *title;
@property (retain) NSString *detail;
@property (retain) LCCProgram *program;
@property (retain) LCCPost *sharedPost;

- (NSString *)categoryString;

@end
