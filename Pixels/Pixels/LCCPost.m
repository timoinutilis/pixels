//
//  LCCPost.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "LCCPost.h"
#import "LCCProgram.h"

@implementation LCCPost

@dynamic user;
@dynamic type;
@dynamic category;
@dynamic image;
@dynamic title;
@dynamic detail;
@dynamic program;
@dynamic programFile;
@dynamic sharedPost;

+ (NSString *)parseClassName
{
    return @"Post";
}

- (NSString *)categoryString
{
    switch (self.category)
    {
        case LCCPostCategoryGame:
            return @"Game";
        case LCCPostCategoryTool:
            return @"Tool";
        case LCCPostCategoryDemo:
            return @"Demo";
        case LCCPostCategoryStatus:
            return @"Status";
        default:
            return @"Unknown";
    }
}

- (NSString *)sourceCode
{
    if (self.programFile)
    {
        // new format
        return [[NSString alloc] initWithData:[self.programFile getData] encoding:NSUTF8StringEncoding];
    }

    // old format
    return self.program.sourceCode;
}

@end
