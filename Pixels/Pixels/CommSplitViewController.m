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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsChanged:) name:NewsNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NewsNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkShowPost];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [AppController sharedController].isCommunityOpen = NO;
}

- (void)newsChanged:(NSNotification *)notification
{
    [self checkShowPost];
}

- (void)checkShowPost
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
