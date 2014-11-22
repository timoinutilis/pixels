//
//  Parser.m
//  Pixels
//
//  Created by Timo Kloss on 20/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Parser.h"
#import "Token.h"
#import "CompilerException.h"

@interface Parser ()

@property NSArray *tokens;
@property NSUInteger currentTokenIndex;
@property Token *token;

@end

@implementation Parser

- (void)parseTokens:(NSArray *)tokens
{
    self.tokens = tokens;
    self.currentTokenIndex = 0;
    self.token = self.tokens[0];
    
    [self acceptProgram];
}

- (void)accept:(TType)tokenType
{
    if (self.token.type == tokenType)
    {
        self.currentTokenIndex++;
        if (self.currentTokenIndex < self.tokens.count)
        {
            self.token = self.tokens[self.currentTokenIndex];
        }
    }
    else
    {
        NSException *exception = [CompilerException exceptionWithName:@"UnexpectedToken"
                                                         reason:[NSString stringWithFormat:@"Expected %@", [Token stringForType:tokenType printable:YES]]
                                                       userInfo:@{@"token": self.token}];
        @throw exception;
    }
}

- (void)acceptProgram
{
    while (self.currentTokenIndex < self.tokens.count)
    {
        if (self.token.type == TTypeIdentifier)
        {
            [self acceptLabel];
        }
        else
        {
            [self acceptCommandLine];
        }
    }
}

- (void)acceptCommandLines
{
    while (self.currentTokenIndex < self.tokens.count && ([self isCommand] || self.token.type == TTypeSymEol))
    {
        [self acceptCommandLine];
    }
}

- (void)acceptCommandLine
{
    if (self.token.type == TTypeSymEol) // empty line
    {
        [self accept:TTypeSymEol];
    }
    else
    {
        [self acceptCommand];
    }
}

- (void)acceptCommand
{
    switch (self.token.type)
    {
        case TTypeSymIf:
            [self acceptIf];
            break;
        case TTypeSymGoto:
            [self acceptGoto];
            break;
        case TTypeSymGosub:
            [self acceptGosub];
            break;
        case TTypeSymReturn:
            [self acceptReturn];
            break;
        case TTypeSymPrint:
            [self acceptPrint];
            break;
        case TTypeSymFor:
            [self acceptForNext];
            break;
        case TTypeSymLet:
            [self acceptLet];
            break;
        case TTypeSymWhile:
            [self acceptWhileWend];
            break;
        case TTypeSymRepeat:
            [self acceptRepeatUntil];
            break;
        case TTypeSymDo:
            [self acceptDoLoop];
            break;
        case TTypeSymExit:
            [self acceptExit];
            break;
        default: {
            NSException *exception = [CompilerException exceptionWithName:@"ExpectedCommand" reason:@"Expected command" userInfo:@{@"token": self.token}];
            @throw exception;
        }
    }
}

- (BOOL)isCommand
{
    switch (self.token.type)
    {
        case TTypeSymIf:
        case TTypeSymGoto:
        case TTypeSymGosub:
        case TTypeSymReturn:
        case TTypeSymPrint:
        case TTypeSymFor:
        case TTypeSymLet:
        case TTypeSymWhile:
        case TTypeSymRepeat:
        case TTypeSymDo:
        case TTypeSymExit:
            return YES;
        default:
            return NO;
    }
    return NO;
}

- (void)acceptLabel
{
    [self accept:TTypeIdentifier];
    [self accept:TTypeSymColon];
    [self acceptEol];
}

- (void)acceptPrint
{
    [self accept:TTypeSymPrint];
    [self acceptExpression];
    [self acceptEol];
}

- (void)acceptGoto
{
    [self accept:TTypeSymGoto];
    [self accept:TTypeIdentifier];
    [self acceptEol];
}

- (void)acceptGosub
{
    [self accept:TTypeSymGosub];
    [self accept:TTypeIdentifier];
    [self acceptEol];
}

- (void)acceptReturn
{
    [self accept:TTypeSymReturn];
    [self acceptEol];
}

- (void)acceptLet
{
    [self accept:TTypeSymLet];
    [self accept:TTypeIdentifier];
    [self accept:TTypeSymOpEq];
    [self acceptExpression];
    [self acceptEol];
}

- (void)acceptIf
{
    [self accept:TTypeSymIf];
    [self acceptCondition];
    [self accept:TTypeSymThen];
    [self acceptCommand]; // includes EOL
}

- (void)acceptForNext
{
    [self accept:TTypeSymFor];
    [self accept:TTypeIdentifier];
    [self accept:TTypeSymOpEq];
    [self acceptExpression];
    [self accept:TTypeSymTo];
    [self acceptExpression];
    [self acceptEol];
    
    [self acceptCommandLines];
    
    [self accept:TTypeSymNext];
    if (self.token.type == TTypeIdentifier)
    {
        [self accept:TTypeIdentifier];
    }
    [self acceptEol];
}

- (void)acceptWhileWend
{
    [self accept:TTypeSymWhile];
    [self acceptCondition];
    [self acceptEol];

    [self acceptCommandLines];
    
    [self accept:TTypeSymWend];
    [self acceptEol];
}

- (void)acceptRepeatUntil
{
    [self accept:TTypeSymRepeat];
    [self acceptEol];
    
    [self acceptCommandLines];
    
    [self accept:TTypeSymUntil];
    [self acceptCondition];
    [self acceptEol];
}

- (void)acceptDoLoop
{
    [self accept:TTypeSymDo];
    [self acceptEol];
    
    [self acceptCommandLines];
    
    [self accept:TTypeSymLoop];
    [self acceptEol];
}

- (void)acceptExit
{
    [self accept:TTypeSymExit];
    [self acceptEol];
}

- (void)acceptEol
{
    if (self.currentTokenIndex < self.tokens.count)
    {
        [self accept:TTypeSymEol];
    }
}

- (void)acceptExpression
{
    [self acceptExpression1];
    while (self.token.type == TTypeSymOpOr) // OR
    {
        [self accept:self.token.type];
        [self acceptExpression1];
    }
}

- (void)acceptExpression1
{
    [self acceptExpression2];
    while (self.token.type == TTypeSymOpAnd) // AND
    {
        [self accept:self.token.type];
        [self acceptExpression1];
    }
}

- (void)acceptExpression2
{
    [self acceptExpression3];
    while (   self.token.type == TTypeSymOpEq // (Un)equal
           || self.token.type == TTypeSymOpUneq)
    {
        [self accept:self.token.type];
        [self acceptExpression3];
    }
}

- (void)acceptExpression3
{
    [self acceptExpression4];
    while (   self.token.type == TTypeSymOpGr // Compare
           || self.token.type == TTypeSymOpLe
           || self.token.type == TTypeSymOpGrEq
           || self.token.type == TTypeSymOpLeEq)
    {
        [self accept:self.token.type];
        [self acceptExpression4];
    }
}

- (void)acceptExpression4
{
    [self acceptExpression5];
    while (   self.token.type == TTypeSymOpPlus // Add, Sub
           || self.token.type == TTypeSymOpMinus)
    {
        [self accept:self.token.type];
        [self acceptExpression5];
    }
}

- (void)acceptExpression5
{
    [self acceptUExpression];
    while (   self.token.type == TTypeSymOpMul // Mul, Div, Mod
           || self.token.type == TTypeSymOpDiv
           || self.token.type == TTypeSymOpMod)
    {
        [self accept:self.token.type];
        [self acceptUExpression];
    }
}

- (void)acceptUExpression
{
    if (   self.token.type == TTypeSymOpPlus // Positive, Negative, Not
        || self.token.type == TTypeSymOpMinus
        || self.token.type == TTypeSymOpNot)
    {
        [self accept:self.token.type];
        [self acceptUExpression];
    }
    else
    {
        [self acceptPExpression];
    }
}

- (void)acceptPExpression
{
    switch (self.token.type)
    {
        case TTypeIdentifier:
            [self accept:TTypeIdentifier];
            break;
        case TTypeNumber:
            [self accept:TTypeNumber];
            break;
        case TTypeSymBracketOpen:
            [self acceptExpressionBlock];
            break;
        default: {
            NSException *exception = [CompilerException exceptionWithName:@"ExpectedExpression" reason:@"Expected expression" userInfo:@{@"token": self.token}];
            @throw exception;
        }
    }
}

- (void)acceptExpressionBlock
{
    [self accept:TTypeSymBracketOpen];
    [self acceptExpression];
    [self accept:TTypeSymBracketClose];
}

- (void)acceptCondition
{
    [self acceptExpression];
}

- (BOOL)isConditionType
{
    switch (self.token.type)
    {
        case TTypeSymOpEq:
        case TTypeSymOpUneq:
        case TTypeSymOpGr:
        case TTypeSymOpLe:
        case TTypeSymOpGrEq:
        case TTypeSymOpLeEq:
            return YES;
        default:
            break;
    }
    return NO;
}

@end
