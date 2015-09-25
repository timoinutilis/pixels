//
//  CommunitySplitViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommSplitViewController.h"
#import "AppController.h"
#import "CommPostViewController.h"
#import "LCCPost.h"

@interface CommSplitViewController ()

@end

@implementation CommSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    
}

- (void)dealloc
{
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [AppController sharedController].isCommunityOpen = YES;
    
    // reset app icon badge
    [AppController sharedController].numNews = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkShowPost:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkShowPost:) name:ShowPostNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [AppController sharedController].isCommunityOpen = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ShowPostNotification object:nil];
}

- (void)checkShowPost:(NSNotification *)notification
{
    NSString *postId = [AppController sharedController].shouldShowPostId;
    if (postId)
    {
        [AppController sharedController].shouldShowPostId = nil;
        
        LCCPost *post = [LCCPost objectWithoutDataWithClassName:[LCCPost parseClassName] objectId:postId];
        
        CommPostViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommPostView"];
        [vc setPost:post mode:CommPostModePost];
        
        UINavigationController *nav = (UINavigationController *)self.viewControllers.lastObject;
        [nav pushViewController:vc animated:YES];
    }
}

@end
