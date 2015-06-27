//
//  Compiler.h
//  Pixels
//
//  Created by Timo Kloss on 27/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Runnable;

@interface Compiler : NSObject

+ (Runnable *)compileSourceCode:(NSString *)sourceCode error:(NSError **)errorPtr;

@end
