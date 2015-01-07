//
//  GORSeparatorView.m
//  Pixels
//
//  Created by Timo Kloss on 6/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORSeparatorView.h"

@implementation GORSeparatorView

- (void)awakeFromNib
{
    self.backgroundColor = [UIColor clearColor];
    self.separatorColor = [UIColor blackColor];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect lineRect = rect;
    lineRect.size.height = 0.5;
    CGContextSetFillColorWithColor(context, self.separatorColor.CGColor);
    CGContextFillRect(context, lineRect);
}

@end
