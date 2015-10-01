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

@interface TabBarController () <UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property NSArray *viewControllers;
@property (nonatomic) UIViewController *selectedViewController;

@end

@implementation TabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (int i = 0; i < self.tabBar.items.count; i++)
    {
        UITabBarItem *item = self.tabBar.items[i];
        item.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
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
    NSInteger index = [self.tabBar.items indexOfObject:item];
    self.selectedViewController = self.viewControllers[index];
}


@end
