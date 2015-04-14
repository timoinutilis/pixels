//
//  AppStyle.m
//  Pixels
//
//  Created by Timo Kloss on 14/4/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AppStyle.h"
#import "UIColor+Utils.h"

@implementation AppStyle

+ (void)styleNavigationController:(UINavigationController *)nav
{
    nav.view.tintColor = [AppStyle tintColor];
    nav.navigationBar.barTintColor = [AppStyle barColor];
    nav.toolbar.barTintColor = [AppStyle barColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [AppStyle darkColor]};
}

+ (UIColor *)barColor
{
    return [UIColor colorWithHex:0x87888a alpha:1.0f];
}

+ (UIColor *)tintColor
{
    return [UIColor colorWithHex:0x00eecd alpha:1.0f];
}

+ (UIColor *)darkColor
{
    return [UIColor colorWithHex:0x23223c alpha:1.0f];
//    return [UIColor colorWithHex:0x1b1d37 alpha:1.0f];
}

+ (UIColor *)brightColor
{
    return [UIColor colorWithHex:0xf6f6f6 alpha:1.0f];
}

+ (UIColor *)alertTintColor
{
    return [UIColor colorWithHex:0x1b1d37 alpha:1.0f];
}

@end
