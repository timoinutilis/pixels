//
//  GameButton.m
//  Pixels
//
//  Created by Timo Kloss on 23/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GameButton.h"

@implementation GameButton

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.hidden && self.userInteractionEnabled)
    {
        int errorMargin = 10;
        CGRect largerFrame = CGRectMake(-errorMargin, -errorMargin, self.frame.size.width + 2 * errorMargin, self.frame.size.height + 2 * errorMargin);
        return CGRectContainsPoint(largerFrame, point) ? self : nil;
    }
    return nil;
}

@end
