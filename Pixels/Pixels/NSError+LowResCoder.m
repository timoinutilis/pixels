//
//  NSError+LowResCoder.m
//  Pixels
//
//  Created by Timo Kloss on 12/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "NSError+LowResCoder.h"
#import "Node.h"
#import "Token.h"

NSString *const LRCErrorDomain = @"com.inutilis.LowResCoder.ErrorDomain";

@implementation NSError (LowResCoder)

+ (NSError *)programErrorWithCode:(LRCErrorCode)code reason:(NSString *)reason position:(NSUInteger)position
{
    return [NSError errorWithDomain:LRCErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:reason, @"position":@(position)}];
}

+ (NSError *)programErrorWithCode:(LRCErrorCode)code reason:(NSString *)reason token:(Token *)token
{
    return [NSError errorWithDomain:LRCErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:reason, @"token": token}];
}

+ (NSError *)typeMismatchErrorWithNode:(Node *)node
{
    return [NSError programErrorWithCode:LRCErrorCodeTypeMismatch reason:@"Type mismatch" token:node.token];
}

+ (NSError *)invalidParameterErrorWithNode:(Node *)node value:(float)value
{
    return [NSError programErrorWithCode:LRCErrorCodeInvalidParameter
                                  reason:[NSString stringWithFormat:@"Invalid parameter (%.*f)", ((int)value == value) ? 0 : 4, value]
                                   token:node.token];
}

+ (NSError *)undefinedLabelErrorWithNode:(Node *)node label:(NSString *)label
{
    return [NSError programErrorWithCode:LRCErrorCodeUndefinedLabel
                                  reason:[NSString stringWithFormat:@"Undefined label %@", label]
                                   token:node.token];
}

+ (NSError *)divisionByZeroErrorWithNode:(Node *)node
{
    return [NSError programErrorWithCode:LRCErrorCodeDivisionByZero reason:@"Division by zero" token:node.token];
}

+ (NSError *)layerNotOpenedErrorWithNode:(Node *)node
{
    return [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"Layer not opened" token:node.token];
}

- (NSUInteger)programPosition
{
    if (self.userInfo[@"position"])
    {
        return [self.userInfo[@"position"] intValue];
    }
    if (self.userInfo[@"token"])
    {
        Token *token = self.userInfo[@"token"];
        return token.position;
    }
    return 0;
}

@end
