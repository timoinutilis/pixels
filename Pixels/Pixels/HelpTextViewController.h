//
//  HelpTextViewController.h
//  Pixels
//
//  Created by Timo Kloss on 25/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HelpContent;

@interface HelpTextViewController : UIViewController <UIWebViewDelegate>

@property (readonly) HelpContent *helpContent;
@property (nonatomic) NSString *chapter;

+ (void)showHelpWithParent:(UIViewController *)parent;

@end
