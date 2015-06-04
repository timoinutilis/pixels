//
//  CommunityListViewController.h
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

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
@end

@interface CommInfoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *infoTextLabel;
@end

@interface CommWriteStatusCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@end

@interface CommPostCell : UITableViewCell
@property (nonatomic) LCCPost *post;
@end