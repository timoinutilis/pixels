//
//  EditorTextView.h
//  Pixels
//
//  Created by Timo Kloss on 25/2/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditorTextView : UITextView

+ (void)setTransferText:(NSString *)text;
+ (NSString *)transferText;

@end
