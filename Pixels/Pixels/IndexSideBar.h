//
//  IndexSideBar.h
//  Pixels
//
//  Created by Timo Kloss on 21/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IndexSideBar : UIControl

@property (nonatomic, weak) UITextView *textView;

- (void)update;

@end
