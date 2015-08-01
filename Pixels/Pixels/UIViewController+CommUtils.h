//
//  UIViewController+CommUtils.h
//  Pixels
//
//  Created by Timo Kloss on 31/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LCCPost;

@interface UIViewController (CommUtils)

- (void)onGetProgramTappedWithPost:(LCCPost *)post;
- (void)closeCommunity;

@end
