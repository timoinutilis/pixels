//
//  Joypad.h
//  Pixels
//
//  Created by Timo Kloss on 31/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Gamepad : UIControl

@property (readonly) BOOL isDirUp;
@property (readonly) BOOL isDirDown;
@property (readonly) BOOL isDirLeft;
@property (readonly) BOOL isDirRight;

@end
