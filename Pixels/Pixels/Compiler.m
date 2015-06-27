//
//  Compiler.m
//  Pixels
//
//  Created by Timo Kloss on 27/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "Compiler.h"
#import "Runnable.h"
#import "Scanner.h"
#import "Parser.h"

@implementation Compiler

+ (Runnable *)compileSourceCode:(NSString *)sourceCode error:(NSError **)errorPtr
{
    Scanner *scanner = [[Scanner alloc] init];
    NSArray *tokens = [scanner tokenizeText:sourceCode];
    
    if (scanner.error)
    {
        if (errorPtr) *errorPtr = scanner.error;
    }
    else if (tokens.count > 0)
    {
        Parser *parser = [[Parser alloc] init];
        NSArray *nodes = [parser parseTokens:tokens];
        
        if (parser.error)
        {
            if (errorPtr) *errorPtr = parser.error;
        }
        else if (nodes.count > 0)
        {
            Runnable *runnable = [[Runnable alloc] initWithNodes:nodes];
            [runnable prepare];
            
            if (runnable.error)
            {
                if (errorPtr) *errorPtr = runnable.error;
            }
            else
            {
                return runnable;
            }
        }
    }
    return nil;
}

@end
