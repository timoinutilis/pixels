//
//  RadialGradientView.m
//  Pixels
//
//  Created by Timo Kloss on 26/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "RadialGradientView.h"

@implementation RadialGradientView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef cx = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGFloat comps[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0};
    CGFloat locs[] = {0.1, 0.2};
    CGGradientRef g = CGGradientCreateWithColorComponents(space, comps, locs, 2);
    
    CGContextDrawRadialGradient(cx, g, _point, 0.0f, _point, MAX(self.bounds.size.width, self.bounds.size.height), 0);
    
    CGGradientRelease(g);
    CGColorSpaceRetain(space);
}

- (void)setPoint:(CGPoint)point
{
    _point = point;
    [self setNeedsDisplay];
}

@end
