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
    LRCErrorCodeLabelAlreadyDefined,
    LRCErrorCodeUndefinedLabel,
    LRCErrorCodeDivisionByZero,
    LRCErrorCodeSemantic,
    LRCErrorCodeRuntime
};

@class Node, Token;

@interface NSError (LowResCoder)

+ (NSError *)programErrorWithCode:(LRCErrorCode)code reason:(NSString *)reason position:(NSUInteger)position;
+ (NSError *)programErrorWithCode:(LRCErrorCode)code reason:(NSString *)reason token:(Token *)token;
+ (NSError *)unexpectedTokenErrorWithToken:(Token *)token;
+ (NSError *)typeMismatchErrorWithNode:(Node *)node;
+ (NSError *)invalidParameterErrorWithNode:(Node *)node value:(float)value;
+ (NSError *)labelAlreadyDefinedErrorWithNode:(Node *)node;
+ (NSError *)undefinedLabelErrorWithNode:(Node *)node label:(NSString *)label;
+ (NSError *)divisionByZeroErrorWithNode:(Node *)node;
+ (NSError *)layerNotOpenedErrorWithNode:(Node *)node;

- (NSUInteger)programPosition;

@end
