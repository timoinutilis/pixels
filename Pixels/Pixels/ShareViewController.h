//
//  ShareViewController.h
//  Pixels
//
//  Created by Timo Kloss on 5/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORMenuTableViewController.h"

@class Project;

@protocol ShareViewControllerDelegate <NSObject>

- (void)onClosedWithSuccess:(BOOL)success;

@end

@interface ShareViewController : GORMenuTableViewController

@property (weak) id <ShareViewControllerDelegate> shareDelegate;
@property Project *project;

+ (UIViewController *)createShareWithDelegate:(id <ShareViewControllerDelegate>)delegate project:(Project *)project;

@end

@interface ShareHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@interface ShareActionCell : UITableViewCell

@end

@interface ShareTextViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end
