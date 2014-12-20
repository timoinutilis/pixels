//
//  RendererView.m
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "RendererView.h"
#import <CoreGraphics/CoreGraphics.h>
#import "Renderer.h"

@implementation RendererView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat components[] = {0.0, 0.0, 0.0, 1.0};
    CGRect myRect;
    
    myRect.origin.x = 0;
    myRect.origin.y = 0;
    myRect.size.width = self.bounds.size.width;
    myRect.size.height = self.bounds.size.height;
    CGContextSetFillColor(context, components);
    CGContextFillRect(context, myRect);
    
    if (self.renderer)
    {
        int size = self.renderer.size;
        
        CGFloat pixelWidth = self.bounds.size.width / size;
        CGFloat pixelHeight = self.bounds.size.height / size;
        myRect.size.width = pixelWidth * 0.99;
        myRect.size.height = pixelHeight * 0.99;
        
        for (int y = 0; y < size; y++)
        {
            myRect.origin.y = y * pixelHeight;
            for (int x = 0; x < size; x++)
            {
                myRect.origin.x = x * pixelWidth;
                uint32_t color = [self.renderer screenColorAtX:x Y:y];
                components[0] = ((color >> 16) & 0xFF) / 255.0;
                components[1] = ((color >> 8) & 0xFF) / 255.0;
                components[2] = (color & 0xFF) / 255.0;
                CGContextSetFillColor(context, components);
                CGContextFillRect(context, myRect);
            }
        }
    }
}

@end
