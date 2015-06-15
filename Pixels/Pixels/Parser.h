//
//  Parser.h
//  Pixels
//
//  Created by Timo Kloss on 20/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Parser : NSObject

@property (nonatomic) NSError *error;

- (NSArray *)parseTokens:(NSArray *)tokens;

@end
