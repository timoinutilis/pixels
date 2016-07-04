//
//  RunnerDelegate.h
//  Pixels
//
//  Created by Timo Kloss on 30/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ButtonType) {
    ButtonTypeUp,
    ButtonTypeDown,
    ButtonTypeLeft,
    ButtonTypeRight,
    ButtonTypeA,
    ButtonTypeB
};

@protocol RunnerDelegate <NSObject>

- (void)runnerLog:(NSString *)message;
- (void)updateRendererView;
- (BOOL)isButtonDown:(ButtonType)type;
- (int)currentGamepadFlags;
- (void)setGamepadModeWithPlayers:(int)players;
- (void)setKeyboardActive:(BOOL)active;

@end
