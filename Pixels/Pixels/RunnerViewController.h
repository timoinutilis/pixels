//
//  RunnerViewController.h
//  Pixels
//
//  Created by Timo Kloss on 30/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RunnerDelegate.h"

@class Project, Runnable;

@interface RunnerViewController : UIViewController <RunnerDelegate>

@property Project *project;
@property Runnable *runnable;

@end
