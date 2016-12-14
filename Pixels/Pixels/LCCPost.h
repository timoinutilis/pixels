//
//  LCCPost.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "APIObject.h"

typedef NS_ENUM(int, LCCPostType) {
    LCCPostTypeUndefined,
    LCCPostTypeProgram,
    LCCPostTypeStatus,
    LCCPostTypeShare,
    LCCPostTypeForum
};

typedef NS_ENUM(int, LCCPostCategory) {
    LCCPostCategoryUndefined = 0,
    
    // Status
    LCCPostCategoryStatus = 1,
    
    // Program
    LCCPostCategoryGame = 2,
    LCCPostCategoryTool,
    LCCPostCategoryDemo,
    
    // Forum
    LCCPostCategoryForumProgramming = 10,
    LCCPostCategoryForumCollaboration,
    LCCPostCategoryForumDiscussion
};

typedef void (^LCCPostLoadSourceCodeBlock)(NSString *sourceCode, NSError *error);

@interface LCCPost : APIObject

@property (retain) NSString *user;
@property LCCPostType type;
@property LCCPostCategory category;
@property (retain) NSURL *image;
@property (retain) NSString *title;
@property (retain) NSString *detail;
@property (retain) NSURL *program;
@property (retain) NSString *sharedPost;
@property (retain) NSString *stats;

@property (nonatomic) BOOL isSourceCodeLoaded;

- (NSString *)categoryString;
- (void)loadSourceCodeWithCompletion:(LCCPostLoadSourceCodeBlock)block;


@end
