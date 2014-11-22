//
//  Scanner.h
//  Pixels
//
//  Created by Timo Kloss on 19/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Scanner : NSObject

- (NSArray *)tokenizeText:(NSString *)text;

@end
