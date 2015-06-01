//
//  UIViewController+LowResCoder.h
//  Pixels
//
//  Created by Timo Kloss on 1/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (LowResCoder)

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message block:(void (^)(void))block;

- (void)presentInNavigationViewController:(UIViewController *)vc;

@end
