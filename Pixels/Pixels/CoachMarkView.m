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

@property (strong) void (^block)();

@end

@implementation CoachMarkView

+ (CoachMarkView *)create
{
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"CoachMarkView" owner:self options:nil];
    CoachMarkView *view = (CoachMarkView *)views[0];
    view.frame = [[UIScreen mainScreen] bounds];
    return view;
}

- (void)showWithText:(NSString *)text image:(NSString *)imageName container:(UIView *)container complete:(void (^)())block
{
    self.block = block;
    
    self.alpha = 0.0;
    self.label.text = text;
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
