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
@property (nonatomic) LCCPost *post;
@end

@interface WriteCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *textView;
- (void)reset;
@end
