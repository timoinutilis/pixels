//
//  GORLabel.m
//  Pixels
//
//  Created by Timo Kloss on 14/4/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORLabel.h"

@implementation GORLabel

- (void)layoutSubviews
{
    self.preferredMaxLayoutWidth = self.frame.size.width;
    [super layoutSubviews];
}

@end
