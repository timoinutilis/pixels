//
//  IndexSideBar.m
//  Pixels
//
//  Created by Timo Kloss on 21/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "IndexSideBar.h"
#import "NSString+Utils.h"
#import "AppStyle.h"

static const CGFloat MARGIN = 3.0;

@interface IndexSideBar()
@property NSInteger numLines;
@property NSArray *markers;
@property NSInteger oldLine;
@property UIView *highlight;
@end

@implementation IndexSideBar

- (void)awakeFromNib
{
    self.backgroundColor = [AppStyle sideBarColor];
    self.alpha = 0.5;
    
    self.highlight = [[UIView alloc] init];
    self.highlight.backgroundColor = [AppStyle tintColor];
    self.highlight.alpha = 0.25;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height - 2.0 - 2 * MARGIN;
    
    CGRect markRect = CGRectMake(MARGIN, 0.0, width - 2 * MARGIN, 2.0);
    CGContextSetFillColorWithColor(context, [AppStyle tintColor].CGColor);
    for (IndexMarker *marker in self.markers)
    {
        markRect.origin.y = floor(MARGIN + marker.line * height / self.numLines);
        CGContextFillRect(context, markRect);
    }
}

- (void)update
{
    NSString *text = self.textView.text;
    NSMutableArray *markers = [NSMutableArray array];
    
    NSUInteger numberOfLines, index, stringLength = [text length];
    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
    {
        NSRange lineRange = [text lineRangeForRange:NSMakeRange(index, 0)];
        
        // check for labels
        NSRange findRange = [text rangeOfString:@":" options:0 range:lineRange];
        if (findRange.location != NSNotFound)
        {
            // ignore BASIC strings
            findRange = [text rangeOfString:@"\"" options:0 range:lineRange];
            if (findRange.location == NSNotFound)
            {
                // ignore REMs
                findRange = [text rangeOfString:@"REM " options:0 range:lineRange];
                if (findRange.location == NSNotFound)
                {
                    IndexMarker *marker = [[IndexMarker alloc] init];
                    marker.line = numberOfLines;
                    marker.range = lineRange;
                    [markers addObject:marker];
                }
            }
        }
        
        // next line
        index = NSMaxRange(lineRange);
    }
    
    self.numLines = numberOfLines;
    self.markers = markers;
    [self setNeedsDisplay];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event
{
    CGPoint point = [touch locationInView:self];
    [self touchedAtY:point.y];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event
{
    CGPoint point = [touch locationInView:self];
    [self touchedAtY:point.y];
    return YES;
}

- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event
{
    [self unhighlight];
}

- (void)cancelTrackingWithEvent:(nullable UIEvent *)event
{
    [self unhighlight];
}

- (void)touchedAtY:(CGFloat)touchY
{
    CGFloat factor = (touchY - 22.0) / (self.bounds.size.height - 44.0);
    if (factor < 0.0) factor = 0.0;
    if (factor > 1.0) factor = 1.0;
    
    NSInteger line = floor(factor * self.numLines);
    
    if (line != self.oldLine)
    {
        IndexMarker *bestMarker = nil;
        NSInteger bestDist = self.numLines;
        NSInteger dist;
        for (IndexMarker *marker in self.markers)
        {
            dist = ABS(marker.line - line);
            if (!bestMarker || dist < bestDist)
            {
                bestMarker = marker;
                bestDist = dist;
            }
        }
        
        CGFloat visibleHeight = self.textView.bounds.size.height - self.textView.contentInset.bottom;
        CGFloat maxOffset = MAX(0.0, self.textView.contentSize.height - visibleHeight);
        CGFloat height = self.bounds.size.height - 2 * MARGIN;
        
        if (bestMarker)
        {
            CGFloat markerY = (bestMarker.line / (CGFloat)self.numLines) * height;
            if (ABS(touchY - markerY) > 22.0)
            {
                bestMarker = nil;
            }
        }
        
        if (bestMarker)
        {
            CGRect rect = [self.textView.layoutManager boundingRectForGlyphRange:bestMarker.range inTextContainer:self.textView.textContainer];
            rect.origin.y += self.textView.textContainerInset.top;
            CGFloat lineCenterY = rect.origin.y + rect.size.height * 0.5;
            [self.textView setContentOffset:CGPointMake(0, MAX(MIN(floor(lineCenterY - visibleHeight * 0.5), maxOffset), 0.0)) animated:NO];
            
            self.highlight.frame = rect;
            if (!self.highlight.superview)
            {
                [self.textView addSubview:self.highlight];
            }
        }
        else
        {
            [self.textView setContentOffset:CGPointMake(0, floor(factor * maxOffset)) animated:NO];
            [self unhighlight];
        }
        
        self.oldLine = line;
    }
}

- (void)unhighlight
{
    if (self.highlight.superview)
    {
        [self.highlight removeFromSuperview];
    }
}

@end


@implementation IndexMarker
@end
