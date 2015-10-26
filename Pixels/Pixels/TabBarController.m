//
//  TabBarController.m
//  Pixels
//
//  Created by Timo Kloss on 1/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "TabBarController.h"
#import "HelpSplitViewController.h"
#import "ExplorerViewController.h"
#import "CommSplitViewController.h"
#import "AppController.h"

@interface TabBarController () <UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property NSArray *viewControllers;
@property (nonatomic) UIViewController *selectedViewController;

@end

@implementation TabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppController sharedController].tabBarController = self;
    
    for (int i = 0; i < self.tabBar.items.count; i++)
    {
        UITabBarItem *item = self.tabBar.items[i];
        item.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        item.selectedImage = [item.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    UIViewController *explorerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ExplorerNav"];

    UIStoryboard *helpStoryboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UIViewController *helpVC = (UIViewController *)[helpStoryboard instantiateInitialViewController];

    UIViewController *aboutVC = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutNav"];
    
    UIStoryboard *communityStoryboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    UIViewController *communityVC = (UIViewController *)[communityStoryboard instantiateInitialViewController];

    self.viewControllers = @[explorerVC, helpVC, aboutVC, communityVC];
    
    self.tabBar.delegate = self;
    
    self.selectedIndex = 0;
    
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

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    self.tabBar.selectedItem = self.tabBar.items[selectedIndex];
    self.selectedViewController = self.viewControllers[selectedIndex];
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
    }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    _selectedIndex = [self.tabBar.items indexOfObject:item];
    self.selectedViewController = self.viewControllers[_selectedIndex];
}

- (void)newsChanged:(NSNotification *)notification
{
    [self updateCommunityBadge];
}

- (void)updateCommunityBadge
{
    NSInteger numNews = [AppController sharedController].numNews;
    UITabBarItem *item = self.tabBar.items[TabIndexCommunity];
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
    if (app.shouldShowPostId && self.selectedIndex != TabIndexCommunity)
    {
        UIViewController *topVC = _selectedViewController;
        if ([topVC isKindOfClass:[UINavigationController class]])
        {
            topVC = ((UINavigationController *)topVC).topViewController;
        }
        if (topVC.presentedViewController)
        {
            [topVC dismissViewControllerAnimated:YES completion:^{
                self.selectedIndex = TabIndexCommunity;
            }];
        }
        else
        {
            self.selectedIndex = TabIndexCommunity;
        }
    }
}

- (void)showExplorerAnimated:(BOOL)animated
{
    self.selectedIndex = TabIndexExplorer;
    UINavigationController *nav = (UINavigationController *)_selectedViewController;
    if (![nav.topViewController isKindOfClass:[ExplorerViewController class]])
    {
        [nav popViewControllerAnimated:animated];
    }
}

- (void)showHelpForChapter:(NSString *)chapter
{
    self.selectedIndex = TabIndexHelp;
    HelpSplitViewController *helpVC = (HelpSplitViewController *)_selectedViewController;
    [helpVC showChapter:chapter];
}

@end
