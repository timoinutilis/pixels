//
//  CompilerException.h
//  Pixels
//
//  Created by Timo Kloss on 22/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Node, Token;

@interface ProgramException : NSException

@property (nonatomic, readonly) NSUInteger position;

+ (ProgramException *)exceptionWithName:(NSString *)name reason:(NSString *)reason position:(NSUInteger)position;
+ (ProgramException *)exceptionWithName:(NSString *)name reason:(NSString *)reason token:(Token *)token;
+ (ProgramException *)typeMismatchExceptionWithNode:(Node *)node;
+ (ProgramException *)invalidParameterExceptionWithNode:(Node *)node;

@end
