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

@interface IndexSideBar()
@property NSInteger numLines;
@property NSArray *markedLines;
@end

@implementation IndexSideBar

- (void)awakeFromNib
{
    self.backgroundColor = [AppStyle sideBarColor];
    self.alpha = 0.5;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height - 2.0 - 3.0;
    
    CGRect markRect = CGRectMake(3.0, 0.0, width - 6.0, 2.0);
    CGContextSetFillColorWithColor(context, [AppStyle tintColor].CGColor);
    for (NSNumber *number in self.markedLines)
    {
        markRect.origin.y = floor(3.0 + number.floatValue * height / self.numLines);
        CGContextFillRect(context, markRect);
    }
}

- (void)setTextView:(UITextView *)textView
{
    _textView = textView;
    [self update];
}

- (void)update
{
    NSString *text = self.textView.text;
    NSMutableArray *marks = [NSMutableArray array];
    
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
                    [marks addObject:@(numberOfLines)];
                }
            }
        }
        
        // next line
        index = NSMaxRange(lineRange);
    }
    
    self.numLines = numberOfLines;
    self.markedLines = marks;
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
}

- (void)cancelTrackingWithEvent:(nullable UIEvent *)event
{
}

- (void)touchedAtY:(CGFloat)touchY
{
    CGFloat row = (touchY - 22.0) / (self.bounds.size.height - 44.0);
    if (row < 0.0) row = 0.0;
    if (row > 1.0) row = 1.0;
    self.textView.contentOffset = CGPointMake(0, floor(row * MAX(0.0, self.textView.contentSize.height - self.textView.bounds.size.height)));
}

@end
