//
//  PublishActivity.m
//  Pixels
//
//  Created by Timo Kloss on 28/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "PublishActivity.h"

@implementation PublishActivity

+ (UIActivityCategory)activityCategory
{
    return UIActivityCategoryShare;
}

- (NSString *)activityType
{
    return @"PublishInutilis";
}

- (NSString *)activityTitle
{
    return @"Publish";
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"dummy_project_icon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
}

- (void)performActivity
{
    // perform in main thread
    [self activityDidFinish:YES];
}

@end
