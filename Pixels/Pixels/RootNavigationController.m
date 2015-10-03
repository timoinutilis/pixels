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
    
}

- (void)dealloc
{
}

/*
- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    self.toolbarHidden = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular);
}

*/
@end
