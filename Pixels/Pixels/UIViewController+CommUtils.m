//
//  UIViewController+CommUtils.m
//  Pixels
//
//  Created by Timo Kloss on 31/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "UIViewController+CommUtils.h"
#import "CommunityModel.h"
#import "ModelManager.h"
#import "ExplorerViewController.h"
#import "AppController.h"

@implementation UIViewController (CommUtils)

- (void)addProgramOfPost:(LCCPost *)post
{
    Project *project = [[ModelManager sharedManager] createNewProject];
    project.name = post.title;
    project.sourceCode = post.program.sourceCode;
    
    [[CommunityModel sharedInstance] countPost:post type:LCCCountTypeDownload];

    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ExplorerRefreshAddedProjectNotification object:self];
        [[AppController sharedController] registerForNotifications];
    }];
}

@end
