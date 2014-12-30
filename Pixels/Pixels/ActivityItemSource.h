//
//  ActivityItemSource.h
//  Pixels
//
//  Created by Timo Kloss on 30/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Project;

@interface ActivityItemSource : NSObject <UIActivityItemSource>

@property Project *project;

@end
