//
//  UIImage+Utils.m
//  Urban Ballr
//
//  Created by Timo Kloss on 30/10/14.
//  Copyright (c) 2014 Gorilla Arm Ltd. All rights reserved.
//

#import "UIImage+Utils.h"

@implementation UIImage (Utils)

- (UIImage *)imageWithMaxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight fill:(BOOL)fill
{
    //scale down
    CGFloat scaleX = maxWidth / self.size.width;
    CGFloat scaleY = maxHeight / self.size.height;
    CGFloat scale = fill ? MAX(scaleX, scaleY) : MIN(scaleX, scaleY);
    
    if (scale < 1.0)
    {
        CGSize size = CGSizeMake(self.size.width * scale, self.size.height * scale);
        
        UIGraphicsBeginImageContext(size);
        [self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return scaledImage;
    }
    return self;
}

- (UIImage *)imageWithSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
    [self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

- (UIImage *)imageAsTemplate
{
    if (self.renderingMode != UIImageRenderingModeAlwaysTemplate)
    {
        return [self imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return self;
}

@end
