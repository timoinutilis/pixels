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
@property IndexMarker *oldMarker;
@property UIView *highlight;
@property NSMutableArray *labels;
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
    UIColor *rectColor = [AppStyle tintColor];
    
    CGRect markRect = CGRectMake(MARGIN, 0.0, width - 2 * MARGIN, 2.0);
    CGContextSetFillColorWithColor(context, rectColor.CGColor);
    for (IndexMarker *marker in self.markers)
    {
        markRect.origin.y = floor(marker.currentBarY);
        CGContextFillRect(context, markRect);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat height = self.bounds.size.height - 2.0 - 2 * MARGIN;
    for (IndexMarker *marker in self.markers)
    {
        marker.currentBarY = MARGIN + marker.line * height / self.numLines;
    }
    [self setNeedsDisplay];
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
                findRange = [text rangeOfString:@"REM " options:NSCaseInsensitiveSearch range:lineRange];
                if (findRange.location == NSNotFound)
                {
                    IndexMarker *marker = [[IndexMarker alloc] init];
                    marker.label = [[text substringWithRange:lineRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
    [self setNeedsLayout];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event
{
    [self showLabels];
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
    self.oldMarker = nil;
    [self unhighlight];
    [self hideLabels];
}

- (void)cancelTrackingWithEvent:(nullable UIEvent *)event
{
    self.oldMarker = nil;
    [self unhighlight];
    [self hideLabels];
}

- (void)touchedAtY:(CGFloat)touchY
{
    IndexMarker *bestMarker = nil;
    CGFloat bestDist = self.bounds.size.height;
    CGFloat dist;
    for (IndexMarker *marker in self.markers)
    {
        dist = ABS(marker.currentBarY - touchY);
        if (dist < 22.0 && (!bestMarker || dist < bestDist))
        {
            bestMarker = marker;
            bestDist = dist;
        }
    }
    
    CGFloat visibleHeight = self.textView.bounds.size.height - self.textView.contentInset.bottom;
    CGFloat maxOffset = MAX(0.0, self.textView.contentSize.height - visibleHeight);
    
    CGFloat scrollCenterY = -1.0;
    if (bestMarker)
    {
        if (bestMarker != self.oldMarker)
        {
            CGRect rect = [self.textView.layoutManager boundingRectForGlyphRange:bestMarker.range inTextContainer:self.textView.textContainer];
            rect.origin.y += self.textView.textContainerInset.top;
            scrollCenterY = rect.origin.y + rect.size.height * 0.5;

            self.highlight.frame = rect;
            if (!self.highlight.superview)
            {
                [self.textView addSubview:self.highlight];
            }
            
            self.oldMarker = bestMarker;
        }
    }
    else
    {
        [self unhighlight];
        self.oldMarker = nil;
        
        CGFloat factor = (touchY - 22.0) / (self.bounds.size.height - 44.0);
        if (factor < 0.0) factor = 0.0;
        if (factor > 1.0) factor = 1.0;
        
        scrollCenterY = factor * self.textView.contentSize.height;
    }
    
    if (scrollCenterY != -1.0)
    {
        [self.textView setContentOffset:CGPointMake(0, MAX(MIN(floor(scrollCenterY - visibleHeight * 0.5), maxOffset), 0.0)) animated:NO];
    }
}

- (void)unhighlight
{
    if (self.highlight.superview)
    {
        [self.highlight removeFromSuperview];
    }
}

- (void)showLabels
{
    self.labels = [NSMutableArray arrayWithCapacity:self.markers.count];
    CGFloat lastBottom = 0.0;
    for (IndexMarker *marker in self.markers)
    {
        if (marker.currentBarY > lastBottom)
        {
            UILabel *label = [[UILabel alloc] init];
            label.userInteractionEnabled = NO;
            label.backgroundColor = [AppStyle barColor];
            label.layer.cornerRadius = 4.0;
            label.clipsToBounds = YES;
            label.textColor = [AppStyle brightColor];
            label.font = [UIFont systemFontOfSize:11];
            label.text = marker.label;
            [label sizeToFit];
            
            CGRect frame = label.frame;
            frame.origin.x = -frame.size.width - 2.0;
            frame.origin.y = MAX(marker.currentBarY - frame.size.height * 0.5, lastBottom);
            label.frame = [self.superview convertRect:frame fromView:self];
            lastBottom = frame.origin.y + frame.size.height + 1.0;
            
            [self.superview addSubview:label];
            [self.labels addObject:label];
        }
    }
}

- (void)hideLabels
{
    for (UILabel *label in self.labels)
    {
        [label removeFromSuperview];
    }
    self.labels = nil;
}

@end


@implementation IndexMarker
@end
