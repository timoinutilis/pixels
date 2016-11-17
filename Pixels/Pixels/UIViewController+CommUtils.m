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
#import "TabBarController.h"

const NSTimeInterval MAX_CACHE_AGE = 1 * 60 * 60;

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
{/*
    Project *project = [[ModelManager sharedManager] createNewProjectInFolder:[ModelManager sharedManager].currentDownloadFolder];
    project.name = post.title;
    project.sourceCode = [post sourceCode];
    project.postId = post.objectId;
    
    if (![post.user isMe])
    {
        [[CommunityModel sharedInstance] countPost:post type:StatsTypeDownload];
    }
    
    BOOL root = (project.parent == [ModelManager sharedManager].rootFolder);
    
    if ([self isModal])
    {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [[AppController sharedController].tabBarController showExplorerAnimated:YES root:root];
        }];
    }
    else
    {
        [[AppController sharedController].tabBarController showExplorerAnimated:NO root:root];
    }*/
}

- (BOOL)isModal
{
    return self.navigationController.presentingViewController != nil;
}

@end
