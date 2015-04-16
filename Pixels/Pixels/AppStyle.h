//
//  AppStyle.h
//  Pixels
//
//  Created by Timo Kloss on 14/4/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppStyle : NSObject

+ (void)styleNavigationController:(UINavigationController *)nav;
+ (UIColor *)barColor;
+ (UIColor *)tintColor;
+ (UIColor *)darkColor;
+ (UIColor *)brightColor;
+ (UIColor *)editorColor;
+ (UIColor *)alertTintColor;

@end
