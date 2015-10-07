//
//  AppStyle.m
//  Pixels
//
//  Created by Timo Kloss on 14/4/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AppStyle.h"
#import "UIColor+Utils.h"
#import "BackgroundView.h"
#import "TextLabel.h"
#import "GORLabel.h"

@implementation AppStyle

+ (void)setAppearance
{
    // App tint color
    UIWindow *window = (UIWindow *)[UIApplication sharedApplication].windows.firstObject;
    window.tintColor = [AppStyle darkTintColor];
    
    // Bars
    [UINavigationBar appearance].barTintColor = [AppStyle barColor];
    [UINavigationBar appearance].tintColor = [AppStyle tintColor];
    [UINavigationBar appearance].translucent = NO;
    [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName: [AppStyle darkColor]};
    [UIToolbar appearanceWhenContainedIn:[UINavigationController class], nil].barTintColor = [AppStyle barColor];
    [UIToolbar appearanceWhenContainedIn:[UINavigationController class], nil].tintColor = [AppStyle tintColor];
    [UIToolbar appearanceWhenContainedIn:[UINavigationController class], nil].translucent = NO;
    [UITabBar appearance].barTintColor = [AppStyle barColor];
    [UITabBar appearance].tintColor = [AppStyle tintColor];
    [UITabBar appearance].translucent = NO;
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[AppStyle darkColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[AppStyle tintColor], NSForegroundColorAttributeName, nil] forState:UIControlStateSelected];
    
    
    // Backgrounds
    [BackgroundView appearance].backgroundColor = [AppStyle brightColor];
    [UIWebView appearance].backgroundColor = [AppStyle brightColor];
    [UITableView appearance].backgroundColor = [AppStyle brightColor];
    [UITableViewCell appearance].backgroundColor = [AppStyle brightColor];
    [UICollectionView appearance].backgroundColor = [AppStyle brightColor];
    [UITextView appearanceWhenContainedIn:[UITableViewCell class], nil].backgroundColor = [AppStyle brightColor];
    
    // Texts
    [TextLabel appearance].textColor = [AppStyle darkColor];
    [GORLabel appearance].textColor = [AppStyle darkColor];
    [UITextField appearance].textColor = [AppStyle darkColor];
    [UITextView appearance].textColor = [AppStyle darkColor];
}

+ (UIColor *)barColor
{
    return [UIColor colorWithHex:0x87888a alpha:1.0f];
}

+ (UIColor *)tintColor
{
    return [UIColor colorWithHex:0x00eecd alpha:1.0f];
}

+ (UIColor *)darkTintColor
{
    return [UIColor colorWithHex:0x05ad96 alpha:1.0f];
}

+ (UIColor *)darkColor
{
    return [UIColor colorWithHex:0x000222 alpha:1.0f];
}

+ (UIColor *)brightColor
{
    return [UIColor colorWithHex:0xf6f6f6 alpha:1.0f];
}

+ (UIColor *)editorColor
{
    return [UIColor colorWithHex:0x0e2a27 alpha:1.0f];
}

+ (UIColor *)warningColor
{
    return [UIColor colorWithHex:0xee0021 alpha:1.0f];
}

@end
