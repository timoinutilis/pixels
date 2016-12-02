//
//  CommStatusUpdateViewController.h
//  Pixels
//
//  Created by Timo Kloss on 26/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "GORMenuTableViewController.h"

@class LCCPost, LCCPostStats;

typedef void (^CommStatusUpdateBlock)(LCCPost *post, LCCPostStats *stats);

@interface CommStatusUpdateViewController : GORMenuTableViewController

+ (UIViewController *)createWithStoryboard:(UIStoryboard *)storyboard completion:(CommStatusUpdateBlock)block;

@end
