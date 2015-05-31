//
//  LCCProgram.h
//  Pixels
//
//  Created by Timo Kloss on 31/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

@interface LCCProgram : PFObject<PFSubclassing>

@property (retain) NSString *sourceCode;

@end
