//
//  NSError+LowResCoder.h
//  Pixels
//
//  Created by Timo Kloss on 12/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const LRCErrorDomain;

typedef NS_ENUM(NSInteger, LRCErrorCode) {
    LRCErrorCodeTokenize = 1,
    LRCErrorCodeParse,
    LRCErrorCodeTypeMismatch,
    LRCErrorCodeInvalidParameter,
    LRCErrorCodeUndefinedLabel,
    LRCErrorCodeSemantic,
    LRCErrorCodeRuntime
};

@class Node, Token;

@interface NSError (LowResCoder)

+ (NSError *)programErrorWithCode:(LRCErrorCode)code reason:(NSString *)reason position:(NSUInteger)position;
+ (NSError *)programErrorWithCode:(LRCErrorCode)code reason:(NSString *)reason token:(Token *)token;
+ (NSError *)typeMismatchErrorWithNode:(Node *)node;
+ (NSError *)invalidParameterErrorWithNode:(Node *)node value:(float)value;
+ (NSError *)undefinedLabelErrorWithNode:(Node *)node label:(NSString *)label;

- (NSUInteger)programPosition;

@end
