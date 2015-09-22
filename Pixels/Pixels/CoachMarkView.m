//
//  HintView.m
//  Pixels
//
//  Created by Timo Kloss on 16/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CoachMarkView.h"

@interface CoachMarkView ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong) void (^block)();

@end

@implementation CoachMarkView

+ (CoachMarkView *)create
{
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"CoachMarkView" owner:self options:nil];
    CoachMarkView *view = (CoachMarkView *)views[0];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    view.frame = window.bounds;
    return view;
}

- (void)showWithText:(NSString *)text image:(NSString *)imageName container:(UIView *)container complete:(void (^)())block
{
    self.block = block;
    
    self.label.text = text;
    self.imageView.image = [UIImage imageNamed:imageName];

    self.alpha = 0.0;
    [container addSubview:self];
    
    [self layoutIfNeeded];
    
    [UIView animateWithDuration:1.0 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)hide
{
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (self.block)
        {
            self.block();
            self.block = nil;
        }
        [self removeFromSuperview];
    }];
}

- (IBAction)onTap:(id)sender
{
    [self hide];
}

@end
