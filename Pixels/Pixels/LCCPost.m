//
//  LCCPost.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "LCCPost.h"

@implementation LCCPost

@dynamic user;
@dynamic type;
@dynamic category;
@dynamic image;
@dynamic title;
@dynamic detail;
@dynamic data;
@dynamic sharedPost;

+ (NSString *)parseClassName
{
    return @"Post";
}

@end
