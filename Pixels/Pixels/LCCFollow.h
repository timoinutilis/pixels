//
//  LCCFollow.h
//  Pixels
//
//  Created by Timo Kloss on 25/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "APIObject.h"

@interface LCCFollow : APIObject

@property (retain) NSString *user;
@property (retain) NSString *followsUser;

@end
