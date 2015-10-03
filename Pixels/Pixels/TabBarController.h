//
//  TabBarController.h
//  Pixels
//
//  Created by Timo Kloss on 1/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TabIndex) {
    TabIndexExplorer,
    TabIndexHelp,
    TabIndexAbout,
    TabIndexCommunity
};

@interface TabBarController : UIViewController

@property (nonatomic) NSInteger selectedIndex;

- (void)showExplorerAnimated:(BOOL)animated;

@end
