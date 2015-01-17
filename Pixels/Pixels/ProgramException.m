//
//  CompilerException.m
//  Pixels
//
//  Created by Timo Kloss on 22/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "ProgramException.h"
#import "Node.h"

@implementation ProgramException

+ (ProgramException *)typeMismatchExceptionWithNode:(Node *)node
{
    return [[ProgramException alloc] initWithName:@"TypeMismatch" reason:@"Type mismatch" userInfo:@{@"node": node}];
}

@end
