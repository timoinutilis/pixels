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
    [UIToolbar appearance].barTintColor = [AppStyle barColor];
    [UIToolbar appearance].tintColor = [AppStyle tintColor];
    [UIToolbar appearance].translucent = NO;
    
    // View
    [UIWebView appearance].backgroundColor = [AppStyle brightColor];
    [UITableView appearance].backgroundColor = [AppStyle brightColor];
    [UITableViewCell appearance].backgroundColor = [AppStyle brightColor];
    [UICollectionView appearance].backgroundColor = [AppStyle brightColor];
    [UITextView appearanceWhenContainedIn:[UITableViewCell class], nil].backgroundColor = [AppStyle brightColor];
    
    //TODO labels! root views!
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

+ (UIColor *)alertTintColor
{
    return [UIColor colorWithHex:0x05ad96 alpha:1.0f];
}

@end
