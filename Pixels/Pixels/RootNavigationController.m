//
//  RootNavigationController.m
//  Pixels
//
//  Created by Timo Kloss on 24/9/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "RootNavigationController.h"
#import "AppController.h"

@interface RootNavigationController () <UITraitEnvironment>

@end

@implementation RootNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkShowPost:) name:ShowPostNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ShowPostNotification object:nil];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    self.toolbarHidden = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkShowPost:nil];
}

- (void)checkShowPost:(NSNotification *)notification
{
    AppController *app = [AppController sharedController];
    if (app.shouldShowPostId && !app.isCommunityOpen)
    {
        UIViewController *topVC = self.topViewController;
        if (topVC.presentedViewController)
        {
            [topVC dismissViewControllerAnimated:YES completion:^{
                [self showCommunity];
            }];
        }
        else
        {
            [self showCommunity];
        }
    }
}

- (void)showCommunity
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    UIViewController *commVC = (UIViewController *)[storyboard instantiateInitialViewController];
    [self presentViewController:commVC animated:YES completion:nil];
}

@end
