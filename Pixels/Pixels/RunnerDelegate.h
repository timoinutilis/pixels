//
//  RunnerDelegate.h
//  Pixels
//
//  Created by Timo Kloss on 30/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RunnerDelegate <NSObject>

- (void)runnerLog:(NSString *)message;
- (void)updateRendererView;

@end
