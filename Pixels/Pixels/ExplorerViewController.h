//
//  ProjectExplorerViewController.h
//  Pixels
//
//  Created by Timo Kloss on 28/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Project;

@interface ExplorerViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@interface ExplorerProjectCell : UICollectionViewCell
@property (nonatomic) Project *project;
- (void)update;
@end