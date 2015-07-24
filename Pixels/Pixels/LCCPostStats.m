//
//  LCCPostStats.m
//  Pixels
//
//  Created by Timo Kloss on 24/7/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "LCCPostStats.h"

NSString *const LCCPostStatsLikesKey = @"numLikes";
NSString *const LCCPostStatsDownloadsKey = @"numDownloads";
NSString *const LCCPostStatsCommentsKey = @"numComments";

@implementation LCCPostStats

@dynamic numLikes;
@dynamic numDownloads;
@dynamic numComments;

+ (NSString *)parseClassName
{
    return @"PostStats";
}

@end
