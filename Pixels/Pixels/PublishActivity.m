//
//  PublishActivity.m
//  Pixels
//
//  Created by Timo Kloss on 28/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "PublishActivity.h"
#import "Project.h"
#import "ShareViewController.h"

NSString *const LowResCoderShare = @"LowResCoderShare";

@interface PublishActivity () <ShareViewControllerDelegate>
@property Project *project;
@end

@implementation PublishActivity

+ (UIActivityCategory)activityCategory
{
    return UIActivityCategoryShare;
}

- (NSString *)activityType
{
    return @"LowResCoderShare";
}

- (NSString *)activityTitle
{
    return @"Community";
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"icon_share"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    self.project = activityItems[0];
}

- (UIViewController *)activityViewController
{
    return [ShareViewController createShareWithDelegate:self project:self.project];
}

- (void)onClosedWithSuccess:(BOOL)success
{
    [self activityDidFinish:success];
}

@end
