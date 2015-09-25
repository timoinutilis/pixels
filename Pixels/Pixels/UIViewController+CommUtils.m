//
//  UIViewController+CommUtils.m
//  Pixels
//
//  Created by Timo Kloss on 31/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "UIViewController+CommUtils.h"
#import "UIViewController+LowResCoder.h"
#import "CommunityModel.h"
#import "ModelManager.h"
#import "ExplorerViewController.h"
#import "AppController.h"

@implementation UIViewController (CommUtils)

- (void)onGetProgramTappedWithPost:(LCCPost *)post
{
    if ([[ModelManager sharedManager] hasProjectWithPostId:post.objectId])
    {
        id __weak weakSelf = self;
        [self showConfirmAlertWithTitle:@"Do you want to get another copy?" message:@"You already got this program." block:^{
            [weakSelf addProgramOfPost:post];
        }];
    }
    else
    {
        [self addProgramOfPost:post];
    }
}

- (void)addProgramOfPost:(LCCPost *)post
{
    NSDictionary *dimensions = @{@"user": [PFUser currentUser] ? @"registered" : @"guest",
                                 @"category": [post categoryString]};

    [PFAnalytics trackEvent:@"get_program" dimensions:dimensions];
    
    Project *project = [[ModelManager sharedManager] createNewProject];
    project.name = post.title;
    project.sourceCode = [post sourceCode];
    project.postId = post.objectId;
    
    [[CommunityModel sharedInstance] countPost:post type:LCCCountTypeDownload];

    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[AppController sharedController] registerForNotifications];
    }];
}

- (void)closeCommunity
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[AppController sharedController] registerForNotifications];
    }];
}

@end
