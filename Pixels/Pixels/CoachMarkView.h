//
//  HintView.h
//  Pixels
//
//  Created by Timo Kloss on 16/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoachMarkView : UIView

+ (CoachMarkView *)create;

- (void)showWithText:(NSString *)text image:(NSString *)imageName container:(UIView *)container complete:(void (^)())block;
- (void)hide;

@end
