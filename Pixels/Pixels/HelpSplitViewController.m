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

@end
