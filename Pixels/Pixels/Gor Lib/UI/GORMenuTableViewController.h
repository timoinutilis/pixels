//
//  GORMenuTableViewController.h
//  Urban Ballr
//
//  Created by Timo Kloss on 11/11/14.
//  Copyright (c) 2014 Gorilla Arm Ltd. All rights reserved.
//

#import "GORTableViewController.h"

@interface GORMenuTableViewController : GORTableViewController

- (void)addCell:(UITableViewCell *)cell;

- (void)addCell:(UITableViewCell *)cell section:(NSInteger)section;

- (void)removeCellWithReuseIdentifier:(NSString *)reuseIdentifier section:(NSInteger)section;

/* If you use a cell as header, add its contentView and not the cell itself */
- (void)setHeader:(UIView *)view section:(NSInteger)section;

- (void)updateSpace;

- (UITableViewCell *)cellWithReuseIdentifier:(NSString *)reuseIdentifier section:(NSInteger)section;

@end

@interface GORSpaceTableViewCell : UITableViewCell
@end

@interface GORMenuSection : NSObject
@property NSMutableArray *cells;
@property UIView *header;
@end
