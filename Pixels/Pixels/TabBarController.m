//
//  TabBarController.m
//  Pixels
//
//  Created by Timo Kloss on 1/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "TabBarController.h"
#import "RootNavigationController.h"
#import "HelpTextViewController.h"
#import "CommSplitViewController.h"
#import "AppController.h"

typedef NS_ENUM(NSInteger, Tab) {
    TabPrograms,
    TabHelp,
    TabAbout,
    TabCommunity
};

@interface TabBarController () <UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property NSArray *viewControllers;
@property (nonatomic) UIViewController *selectedViewController;
@property NSInteger selectedIndex;

@end

@implementation TabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (int i = 0; i < self.tabBar.items.count; i++)
    {
        UITabBarItem *item = self.tabBar.items[i];
        item.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        item.selectedImage = [item.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    RootNavigationController *projectsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ExplorerNav"];

    UIStoryboard *helpStoryboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UIViewController *helpVC = (UIViewController *)[helpStoryboard instantiateInitialViewController];

    UIViewController *aboutVC = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutNav"];
    
    UIStoryboard *communityStoryboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    UIViewController *communityVC = (UIViewController *)[communityStoryboard instantiateInitialViewController];

    self.viewControllers = @[projectsVC, helpVC, aboutVC, communityVC];
    
    self.tabBar.delegate = self;
    
    self.tabBar.selectedItem = self.tabBar.items[0];
    self.selectedViewController = self.viewControllers[0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsChanged:) name:NewsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkShowPost:) name:ShowPostNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NewsNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ShowPostNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateCommunityBadge];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkShowPost:nil];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    if (_selectedViewController)
    {
        [_selectedViewController willMoveToParentViewController:nil];
        [_selectedViewController.view removeFromSuperview];
        [_selectedViewController removeFromParentViewController];
    }
    _selectedViewController = selectedViewController;
    if (_selectedViewController)
    {
        _selectedViewController.view.frame = self.containerView.bounds;
        [self addChildViewController:_selectedViewController];
        [self.containerView addSubview:_selectedViewController.view];
        [_selectedViewController didMoveToParentViewController:self];
        self.selectedIndex = [self.viewControllers indexOfObject:_selectedViewController];
    }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSInteger index = [self.tabBar.items indexOfObject:item];
    self.selectedViewController = self.viewControllers[index];
}

- (void)newsChanged:(NSNotification *)notification
{
    [self updateCommunityBadge];
}

- (void)updateCommunityBadge
{
    NSInteger numNews = [AppController sharedController].numNews;
    UITabBarItem *item = self.tabBar.items[TabCommunity];
    if (numNews > 0)
    {
        item.badgeValue = @(numNews).stringValue;
    }
    else
    {
        item.badgeValue = nil;
    }
}

- (void)checkShowPost:(NSNotification *)notification
{
    AppController *app = [AppController sharedController];
    if (app.shouldShowPostId && self.selectedIndex != TabCommunity)
    {
        UIViewController *topVC = _selectedViewController;
        if ([topVC isKindOfClass:[UINavigationController class]])
        {
            topVC = ((UINavigationController *)topVC).topViewController;
        }
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
    self.tabBar.selectedItem = self.tabBar.items[TabCommunity];
    self.selectedViewController = self.viewControllers[TabCommunity];
}

@end
