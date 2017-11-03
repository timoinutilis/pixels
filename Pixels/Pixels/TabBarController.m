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
#import "CommunityModel.h"
#import "ModelManager.h"

@interface TabBarController ()

@end

@implementation TabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppController sharedController].tabBarController = self;
    
    /*
    for (int i = 0; i < self.tabBar.items.count; i++)
    {
        UITabBarItem *item = self.tabBar.items[i];
        item.image = [item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        item.selectedImage = [item.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
*/
    UIViewController *explorerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ExplorerNav"];

    UIStoryboard *helpStoryboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UIViewController *helpVC = (UIViewController *)[helpStoryboard instantiateInitialViewController];

    UIViewController *aboutVC = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutNav"];
    
    UIStoryboard *communityStoryboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    UIViewController *communityVC = (UIViewController *)[communityStoryboard instantiateInitialViewController];

    explorerVC.tabBarItem = [self itemWithTitle:@"My Programs" imageName:@"programs"];
    helpVC.tabBarItem = [self itemWithTitle:@"Help" imageName:@"help"];
    aboutVC.tabBarItem = [self itemWithTitle:@"About" imageName:@"about"];
    communityVC.tabBarItem = [self itemWithTitle:@"Community" imageName:@"community"];
    
    self.viewControllers = @[explorerVC, helpVC, aboutVC, communityVC];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationsNumChanged:) name:NotificationsNumChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkShowPost:) name:ShowPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkImportProject:) name:ImportProjectNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationsNumChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ShowPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ImportProjectNotification object:nil];
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
    [self checkImportProject:nil];
}

- (UITabBarItem *)itemWithTitle:(NSString *)title imageName:(NSString *)imageName
{
    return [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:imageName] selectedImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@sel", imageName]]];
}

- (void)notificationsNumChanged:(NSNotification *)notification
{
    [self updateCommunityBadge];
}

- (void)updateCommunityBadge
{
    NSInteger num = [CommunityModel sharedInstance].numNewNotifications;
    UITabBarItem *item = self.tabBar.items[TabIndexCommunity];
    if (num > 0)
    {
        item.badgeValue = @(num).stringValue;
    }
    else
    {
        item.badgeValue = nil;
    }
}

- (void)dismissPresentedViewController:(void (^)(void))completion
{
    UIViewController *topVC = self.selectedViewController;
    if ([topVC isKindOfClass:[UINavigationController class]])
    {
        topVC = ((UINavigationController *)topVC).topViewController;
    }
    if (topVC.presentedViewController)
    {
        [topVC dismissViewControllerAnimated:YES completion:completion];
    }
    else
    {
        completion();
    }
}

- (void)checkShowPost:(NSNotification *)notification
{
    AppController *app = [AppController sharedController];
    if (app.shouldShowPostId && self.selectedIndex != TabIndexCommunity)
    {
        [self dismissPresentedViewController:^{
            self.selectedIndex = TabIndexCommunity;
        }];
    }
}

- (void)checkImportProject:(NSNotification *)notification
{
    AppController *app = [AppController sharedController];
    if (app.shouldImportProject)
    {
        __weak TabBarController *weakSelf = self;
        
        [self dismissPresentedViewController:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Do you want to add \"%@\" as a new program?", app.shouldImportProject.name]
                                                                           message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                app.shouldImportProject = nil;
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf importProject:app.shouldImportProject];
                app.shouldImportProject = nil;
            }]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }
}

- (void)importProject:(TempProject *)tempProject
{
    Project *project = [[ModelManager sharedManager] createNewProjectInFolder:[ModelManager sharedManager].rootFolder];
    project.name = tempProject.name;
    project.sourceCode = tempProject.sourceCode;
    
    [self showExplorerAnimated:YES root:YES];
}

- (void)showExplorerAnimated:(BOOL)animated root:(BOOL)root
{
    self.selectedIndex = TabIndexExplorer;
    UINavigationController *nav = (UINavigationController *)self.selectedViewController;
    if (root)
    {
        [nav popToRootViewControllerAnimated:animated];
    }
    else
    {
        if (![nav.topViewController isKindOfClass:[ExplorerViewController class]])
        {
            [nav popViewControllerAnimated:animated];
        }
    }
}

- (void)showHelpForChapter:(NSString *)chapter
{
    self.selectedIndex = TabIndexHelp;
    HelpSplitViewController *helpVC = (HelpSplitViewController *)self.selectedViewController;
    [helpVC showChapter:chapter];
}

@end
