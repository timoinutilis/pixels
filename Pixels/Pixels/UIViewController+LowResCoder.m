//
//  UIViewController+LowResCoder.m
//  Pixels
//
//  Created by Timo Kloss on 1/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "UIViewController+LowResCoder.h"

@implementation UIViewController (LowResCoder)

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message block:(void (^)(void))block
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (block)
        {
            block();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
