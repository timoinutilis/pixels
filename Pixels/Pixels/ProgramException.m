//
//  CompilerException.m
//  Pixels
//
//  Created by Timo Kloss on 22/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "ProgramException.h"
#import "Node.h"
#import "Token.h"

@implementation ProgramException

+ (ProgramException *)exceptionWithName:(NSString *)name reason:(NSString *)reason position:(NSUInteger)position;
{
    return [[ProgramException alloc] initWithName:name reason:reason userInfo:@{@"position":@(position)}];
}

+ (ProgramException *)exceptionWithName:(NSString *)name reason:(NSString *)reason token:(Token *)token
{
    return [[ProgramException alloc] initWithName:name reason:reason userInfo:@{@"token": token}];
}

+ (ProgramException *)typeMismatchExceptionWithNode:(Node *)node
{
    return [[ProgramException alloc] initWithName:@"TypeMismatch" reason:@"Type mismatch" userInfo:@{@"token": node.token}];
}

+ (ProgramException *)invalidParameterExceptionWithNode:(Node *)node value:(float)value
{
    return [[ProgramException alloc] initWithName:@"InvalidParameter"
                                           reason:[NSString stringWithFormat:@"Invalid parameter (%.*f)", ((int)value == value) ? 0 : 4, value]
                                         userInfo:@{@"token": node.token}];
}

- (NSUInteger)position
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
