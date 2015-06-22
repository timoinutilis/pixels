//
//  CommunityListViewController.h
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GORTextView.h"

@class LCCUser, LCCPost;

typedef NS_ENUM(NSInteger, CommListMode) {
    CommListModeUndefined = 0,
    CommListModeProfile,
    CommListModeNews
};

@interface CommDetailViewController : UITableViewController

- (void)setUser:(LCCUser *)user mode:(CommListMode)mode;

@end



@interface CommProfileCell : UITableViewCell
@property (nonatomic) LCCUser *user;
- (void)toggleDetailSize;
@end

@interface CommInfoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *infoTextLabel;
@end

@interface CommWriteStatusCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet GORTextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *detailPlaceholderLabel;
@end

@interface CommPostCell : UITableViewCell
@property (nonatomic) LCCPost *post;
@end
