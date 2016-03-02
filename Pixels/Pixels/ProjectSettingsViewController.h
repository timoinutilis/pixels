//
//  ProjectSettingsViewController.h
//  Pixels
//
//  Created by Timo Kloss on 1/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Project;

@interface ProjectSettingsViewController : UITableViewController

@property Project *project;
@property NSArray <UIImage *> *snapshotImages;

@end

@interface IconSelectorTableViewCell : UITableViewCell
@property (nonatomic) NSArray <UIImage *> *images;
@end

@interface IconSelectorImageCollectionViewCell : UICollectionViewCell
@property (nonatomic) UIImage *image;
@end