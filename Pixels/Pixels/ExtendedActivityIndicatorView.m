//
//  ExtendedActivityIndicatorView.m
//  Pixels
//
//  Created by Timo Kloss on 5/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "ExtendedActivityIndicatorView.h"

@interface ExtendedActivityIndicatorView()
@property int numActivities;
@end

@implementation ExtendedActivityIndicatorView

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    self.hidesWhenStopped = YES;
}

- (void)increaseActivity
{
    if (self.numActivities == 0)
    {
        [self startAnimating];
    }
    self.numActivities++;
}

- (void)decreaseActivity
{
    self.numActivities--;
    if (self.numActivities == 0)
    {
        [self stopAnimating];
    }
}

@end
