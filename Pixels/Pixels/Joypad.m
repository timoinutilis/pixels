//
//  Joypad.m
//  Pixels
//
//  Created by Timo Kloss on 31/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Joypad.h"

@implementation Joypad

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL begin = [super beginTrackingWithTouch:touch withEvent:event];
    if (begin)
    {
        [self updateDirectionsWithTouch:touch];
    }
    return begin;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL cont = [super continueTrackingWithTouch:touch withEvent:event];
    if (cont)
    {
        [self updateDirectionsWithTouch:touch];
    }
    return cont;
}

- (void)endTrackingWithTouch:(UITouch *)touches withEvent:(UIEvent *)event
{
    [self resetDirections];
    [super endTrackingWithTouch:touches withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [self resetDirections];
    [super cancelTrackingWithEvent:event];
}

- (void)updateDirectionsWithTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:self];
    point.x -= self.bounds.size.width * 0.5;
    point.y -= self.bounds.size.height * 0.5;
    _isDirUp = (point.y < -20.0);
    _isDirDown = (point.y > 20.0);
    _isDirLeft = (point.x < -20.0);
    _isDirRight = (point.x > 20.0);
}

- (void)resetDirections
{
    _isDirUp = NO;
    _isDirDown = NO;
    _isDirLeft = NO;
    _isDirRight = NO;
}

@end
