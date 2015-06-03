//
//  CommPostViewController.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CommPostMode) {
    CommPostModeUndefined = 0,
    CommPostModeProgram,
    CommPostModeStatus
};

@class LCCPost;

@interface CommPostViewController : UITableViewController

- (void)setPost:(LCCPost *)post mode:(CommPostMode)mode;

@end

@interface ProgramTitleCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *getProgramButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic) LCCPost *post;
@property (nonatomic) NSInteger likeCount;
@property (nonatomic) NSInteger downloadCount;
- (void)likeIt;
@end

@interface WriteCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *textView;
- (void)reset;
@end
