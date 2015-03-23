//
//  Joypad.m
//  Pixels
//
//  Created by Timo Kloss on 31/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Gamepad.h"

typedef NS_ENUM(NSInteger, GamepadImage) {
    GamepadImageNormal,
    GamepadImageUp,
    GamepadImageUpRight,
    GamepadImageRight,
    GamepadImageDownRight,
    GamepadImageDown,
    GamepadImageDownLeft,
    GamepadImageLeft,
    GamepadImageUpLeft
};

@interface Gamepad ()

@property UIImageView *imageView;
@property NSArray *images;

@end

@implementation Gamepad

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setUpView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setUpView];
    }
    return self;
}

- (void)setUpView
{
    self.backgroundColor = [UIColor clearColor];
    
    self.images = @[[UIImage imageNamed:@"joypad"],
                    [UIImage imageNamed:@"joypad_pressed_u"],
                    [UIImage imageNamed:@"joypad_pressed_ur"],
                    [UIImage imageNamed:@"joypad_pressed_r"],
                    [UIImage imageNamed:@"joypad_pressed_dr"],
                    [UIImage imageNamed:@"joypad_pressed_d"],
                    [UIImage imageNamed:@"joypad_pressed_dl"],
                    [UIImage imageNamed:@"joypad_pressed_l"],
                    [UIImage imageNamed:@"joypad_pressed_ul"]];
    
    self.imageView = [[UIImageView alloc] initWithImage:self.images[GamepadImageNormal]];
    self.imageView.alpha = 0.5;
    [self addSubview:self.imageView];
}

- (CGSize)intrinsicContentSize
{
    UIImage *image = self.images[0];
    return image.size;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.hidden && self.userInteractionEnabled)
    {
        int errorMargin = 40;
        CGRect largerFrame = CGRectMake(-errorMargin, -errorMargin, self.frame.size.width + 2 * errorMargin, self.frame.size.height + 2 * errorMargin);
        return CGRectContainsPoint(largerFrame, point) ? self : nil;
    }
    return nil;
}

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
    _isDirUp = (point.y < -20.0) && ABS(point.x / point.y) < 2.0;
    _isDirDown = (point.y > 20.0) && ABS(point.x / point.y) < 2.0;
    _isDirLeft = (point.x < -20.0) && ABS(point.y / point.x) < 2.0;
    _isDirRight = (point.x > 20.0) && ABS(point.y / point.x) < 2.0;
    [self updateImage];
}

- (void)resetDirections
{
    _isDirUp = NO;
    _isDirDown = NO;
    _isDirLeft = NO;
    _isDirRight = NO;
    [self updateImage];
}

- (void)updateImage
{
    GamepadImage gi = GamepadImageNormal;
    if (_isDirUp)
    {
        if (_isDirLeft)
        {
            gi = GamepadImageUpLeft;
        }
        else if (_isDirRight)
        {
            gi = GamepadImageUpRight;
        }
        else
        {
            gi = GamepadImageUp;
        }
    }
    else if (_isDirDown)
    {
        if (_isDirLeft)
        {
            gi = GamepadImageDownLeft;
        }
        else if (_isDirRight)
        {
            gi = GamepadImageDownRight;
        }
        else
        {
            gi = GamepadImageDown;
        }
    }
    else if (_isDirLeft)
    {
        gi = GamepadImageLeft;
    }
    else if (_isDirRight)
    {
        gi = GamepadImageRight;
    }
    
    self.imageView.image = self.images[gi];
}

@end
