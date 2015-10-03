//
//  HelpSplitViewController.m
//  Pixels
//
//  Created by Timo Kloss on 1/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "HelpSplitViewController.h"
#import "HelpContent.h"

@interface HelpSplitViewController () <UISplitViewControllerDelegate>

@end

@implementation HelpSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    self.preferredPrimaryColumnWidthFraction = 0.3;

    NSURL *url = [[NSBundle mainBundle] URLForResource:@"manual" withExtension:@"html"];
    _helpContent = [[HelpContent alloc] initWithURL:url];
    
    _detailNavigationController = self.viewControllers.lastObject;
}

// Override this method to customize the behavior of `showViewController:` on a split view controller. Return YES to indicate that you've handled
// the action yourself; return NO to cause the default behavior to be executed.
- (BOOL)splitViewController:(UISplitViewController *)splitViewController showViewController:(UIViewController *)vc sender:(nullable id)sender
{
    return NO;
}

// Override this method to customize the behavior of `showDetailViewController:` on a split view controller. Return YES to indicate that you've
// handled the action yourself; return NO to cause the default behavior to be executed.
- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(nullable id)sender
{
    return NO;
}

@end
