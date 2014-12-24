//
//  Parser.m
//  Pixels
//
//  Created by Timo Kloss on 20/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Parser.h"
#import "Token.h"
#import "Node.h"
#import "CompilerException.h"

@interface Parser ()

@property NSArray *tokens;
@property NSUInteger currentTokenIndex;
@property Token *token;

@end

@implementation Parser

- (NSArray *)parseTokens:(NSArray *)tokens
{
    self.tokens = tokens;
    self.currentTokenIndex = 0;
    self.token = self.tokens[0];
    
    return [self acceptProgram];
}

#pragma mark - Basics

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

- (void)acceptEol
{
    if (self.currentTokenIndex < self.tokens.count)
    {
        [self accept:TTypeSymEol];
    }
}

#pragma mark - Lines

- (NSArray *)acceptProgram
{
    NSMutableArray *nodes = [NSMutableArray array];
    while (self.currentTokenIndex < self.tokens.count)
    {
        Node *node;
        if (self.token.type == TTypeIdentifier)
        {
            node = [self acceptLabel];
        }
        else
        {
            node = [self acceptCommandLine];
        }
        if (node)
        {
            [nodes addObject:node];
        }
    }
    return nodes;
}

- (NSMutableArray *)acceptCommandLines
{
    NSMutableArray *nodes = [NSMutableArray array];
    while (self.currentTokenIndex < self.tokens.count && ([self isCommand] || self.token.type == TTypeSymEol))
    {
        Node *node = [self acceptCommandLine];
        if (node)
        {
            [nodes addObject:node];
        }
    }
    return nodes;
}

- (Node *)acceptCommandLine
{
    Node *node = nil;
    if (self.token.type == TTypeSymEol) // empty line
    {
        [self accept:TTypeSymEol];
    }
    else
    {
        node = [self acceptCommand];
    }
    return node;
}

- (Node *)acceptCommand
{
    Node *node;
    switch (self.token.type)
    {
        case TTypeSymIf:
            node = [self acceptIf];
            break;
        case TTypeSymGoto:
            node = [self acceptGoto];
            break;
        case TTypeSymGosub:
            node = [self acceptGosub];
            break;
        case TTypeSymReturn:
            node = [self acceptReturn];
            break;
        case TTypeSymPrint:
            node = [self acceptPrint];
            break;
        case TTypeSymFor:
            node = [self acceptForNext];
            break;
        case TTypeSymLet:
            node = [self acceptLet];
            break;
        case TTypeSymWhile:
            node = [self acceptWhileWend];
            break;
        case TTypeSymRepeat:
            node = [self acceptRepeatUntil];
            break;
        case TTypeSymDo:
            node = [self acceptDoLoop];
            break;
        case TTypeSymExit:
            node = [self acceptExit];
            break;
        case TTypeSymWait:
            node = [self acceptWait];
            break;
        case TTypeSymColor:
            node = [self acceptColor];
            break;
        case TTypeSymCls:
            node = [self acceptCls];
            break;
        case TTypeSymPlot:
            node = [self acceptPlot];
            break;
        case TTypeSymLine:
            node = [self acceptLine];
            break;
        case TTypeSymBox:
            node = [self acceptBox];
            break;
        case TTypeSymText:
            node = [self acceptText];
            break;
        default: {
            NSException *exception = [CompilerException exceptionWithName:@"ExpectedCommand" reason:@"Expected command" userInfo:@{@"token": self.token}];
            @throw exception;
        }
    }
    return node;
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
        case TTypeSymWait:
        case TTypeSymColor:
        case TTypeSymCls:
        case TTypeSymPlot:
        case TTypeSymLine:
        case TTypeSymBox:
        case TTypeSymText:
            return YES;
        default:
            return NO;
    }
    return NO;
}

- (Node *)acceptLabel
{
    LabelNode *node = [[LabelNode alloc] init];
    node.identifier = self.token.attrString;
    [self accept:TTypeIdentifier];
    [self accept:TTypeSymColon];
    [self acceptEol];
    return node;
}

#pragma mark - Commands

- (Node *)acceptPrint
{
    PrintNode *node = [[PrintNode alloc] init];
    [self accept:TTypeSymPrint];
    node.expression = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptGoto
{
    GotoNode *node = [[GotoNode alloc] init];
    [self accept:TTypeSymGoto];
    node.label = self.token.attrString;
    [self accept:TTypeIdentifier];
    [self acceptEol];
    return node;
}

- (Node *)acceptGosub
{
    GosubNode *node = [[GosubNode alloc] init];
    [self accept:TTypeSymGosub];
    node.label = self.token.attrString;
    [self accept:TTypeIdentifier];
    [self acceptEol];
    return node;
}

- (Node *)acceptReturn
{
    ReturnNode *node = [[ReturnNode alloc] init];
    [self accept:TTypeSymReturn];
    [self acceptEol];
    return node;
}

- (Node *)acceptLet
{
    LetNode *node = [[LetNode alloc] init];
    [self accept:TTypeSymLet];
    node.identifier = self.token.attrString;
    [self accept:TTypeIdentifier];
    [self accept:TTypeSymOpEq];
    node.expression = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptIf
{
    IfNode *node = [[IfNode alloc] init];
    [self accept:TTypeSymIf];
    node.condition = [self acceptExpression];
    [self accept:TTypeSymThen];
    if (self.token.type == TTypeSymEol)
    {
        // if ... end-if block
        node.commands = [self acceptCommandLines];
        [self accept:TTypeSymEnd];
        [self accept:TTypeSymIf];
        [self accept:TTypeSymEol];
    }
    else
    {
        // single line
        node.commands = @[[self acceptCommand]]; // includes EOL
    }
    return node;
}

- (Node *)acceptForNext
{
    ForNextNode *node = [[ForNextNode alloc] init];
    [self accept:TTypeSymFor];
    node.variable = self.token.attrString;
    [self accept:TTypeIdentifier];
    [self accept:TTypeSymOpEq];
    node.startExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.endExpression = [self acceptExpression];
    [self acceptEol];
    
    node.commands = [self acceptCommandLines];
    
    [self accept:TTypeSymNext];
    if (self.token.type == TTypeIdentifier)
    {
        [self accept:TTypeIdentifier];
    }
    [self acceptEol];
    return node;
}

- (Node *)acceptWhileWend
{
    WhileWendNode *node = [[WhileWendNode alloc] init];
    [self accept:TTypeSymWhile];
    node.condition = [self acceptExpression];
    [self acceptEol];

    node.commands = [self acceptCommandLines];
    
    [self accept:TTypeSymWend];
    [self acceptEol];
    return node;
}

- (Node *)acceptRepeatUntil
{
    RepeatUntilNode *node = [[RepeatUntilNode alloc] init];
    [self accept:TTypeSymRepeat];
    [self acceptEol];
    
    node.commands = [self acceptCommandLines];
    
    [self accept:TTypeSymUntil];
    node.condition = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptDoLoop
{
    DoLoopNode *node = [[DoLoopNode alloc] init];
    [self accept:TTypeSymDo];
    [self acceptEol];
    
    node.commands = [self acceptCommandLines];
    
    [self accept:TTypeSymLoop];
    [self acceptEol];
    return node;
}

- (Node *)acceptExit
{
    ExitNode *node = [[ExitNode alloc] init];
    [self accept:TTypeSymExit];
    [self acceptEol];
    return node;
}

- (Node *)acceptWait
{
    WaitNode *node = [[WaitNode alloc] init];
    [self accept:TTypeSymWait];
    node.time = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptColor
{
    ColorNode *node = [[ColorNode alloc] init];
    [self accept:TTypeSymColor];
    node.color = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptCls
{
    ClsNode *node = [[ClsNode alloc] init];
    [self accept:TTypeSymCls];
    node.color = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptPlot
{
    PlotNode *node = [[PlotNode alloc] init];
    [self accept:TTypeSymPlot];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptLine
{
    LineNode *node = [[LineNode alloc] init];
    [self accept:TTypeSymLine];
    node.fromXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.fromYExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.toXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.toYExpression = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptBox
{
    BoxNode *node = [[BoxNode alloc] init];
    [self accept:TTypeSymBox];
    node.fromXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.fromYExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.toXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.toYExpression = [self acceptExpression];
    [self acceptEol];
    return node;
}

- (Node *)acceptText
{
    TextNode *node = [[TextNode alloc] init];
    [self accept:TTypeSymText];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.valueExpression = [self acceptExpression];
    if (self.token.type == TTypeSymComma)
    {
        [self accept:TTypeSymComma];
        node.alignExpression = [self acceptExpression];
    }
    [self acceptEol];
    return node;
}

#pragma mark - Expressions

- (Node *)acceptExpression
{
    return [self acceptExpressionLevel:0];
}

- (Node *)acceptExpressionLevel:(int)level
{
    static NSArray *operatorLevels = nil;
    if (!operatorLevels)
    {
        operatorLevels = @[
                           @[@(TTypeSymOpOr)],
                           @[@(TTypeSymOpAnd)],
                           @[@(TTypeSymOpEq), @(TTypeSymOpUneq)],
                           @[@(TTypeSymOpGr), @(TTypeSymOpLe), @(TTypeSymOpGrEq), @(TTypeSymOpLeEq)],
                           @[@(TTypeSymOpPlus), @(TTypeSymOpMinus)],
                           @[@(TTypeSymOpMul), @(TTypeSymOpDiv), @(TTypeSymOpMod)]
                           ];
    }
    
    if (level == operatorLevels.count)
    {
        return [self acceptUnaryExpression];
    }
    
    NSArray *operators = operatorLevels[level];
    Node *node = [self acceptExpressionLevel:level + 1];
    while ([operators indexOfObject:@(self.token.type)] != NSNotFound)
    {
        Operator2Node *newNode = [[Operator2Node alloc] init];
        newNode.leftExpression = node;
        newNode.type = self.token.type;
        [self accept:self.token.type];
        newNode.rightExpression = [self acceptExpressionLevel:level + 1];
        node = newNode;
    }
    return node;
}

- (Node *)acceptUnaryExpression
{
    if (   self.token.type == TTypeSymOpPlus
        || self.token.type == TTypeSymOpMinus
        || self.token.type == TTypeSymOpNot)
    {
        Operator1Node *node = [[Operator1Node alloc] init];
        node.type = self.token.type;
        [self accept:self.token.type];
        node.expression = [self acceptUnaryExpression];
        return node;
    }
    return [self acceptPrimaryExpression];
}

- (Node *)acceptPrimaryExpression
{
    Node *functionNode = [self acceptFunction];
    if (functionNode)
    {
        return functionNode;
    }
    
    switch (self.token.type)
    {
        case TTypeIdentifier: {
            VariableNode *node = [[VariableNode alloc] init];
            node.identifier = self.token.attrString;
            [self accept:TTypeIdentifier];
            return node;
        }
        case TTypeNumber: {
            NumberNode *node = [[NumberNode alloc] init];
            node.value = self.token.attrNumber;
            [self accept:TTypeNumber];
            return node;
        }
        case TTypeString: {
            StringNode *node = [[StringNode alloc] init];
            node.value = self.token.attrString;
            [self accept:TTypeString];
            return node;
        }
        case TTypeSymBracketOpen: {
            return [self acceptExpressionBlock];
        }
        case TTypeSymTrue: {
            NumberNode *node = [[NumberNode alloc] init];
            node.value = -1;
            [self accept:TTypeSymTrue];
            return node;
        }
        case TTypeSymFalse: {
            NumberNode *node = [[NumberNode alloc] init];
            node.value = 0;
            [self accept:TTypeSymFalse];
            return node;
        }
        default: {
            NSException *exception = [CompilerException exceptionWithName:@"ExpectedExpression" reason:@"Expected expression" userInfo:@{@"token": self.token}];
            @throw exception;
        }
    }
    return nil;
}

- (Node *)acceptExpressionBlock
{
    Node *node;
    [self accept:TTypeSymBracketOpen];
    node = [self acceptExpression];
    [self accept:TTypeSymBracketClose];
    return node;
}

- (Node *)acceptFunction
{
    switch (self.token.type)
    {
        case TTypeSymUp:
        case TTypeSymDown:
        case TTypeSymLeft:
        case TTypeSymRight:
        case TTypeSymButton: {
            JoystickNode *node = [[JoystickNode alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
            [self accept:TTypeSymBracketOpen];
            node.portExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymPoint: {
            PointNode *node = [[PointNode alloc] init];
            [self accept:TTypeSymPoint];
            [self accept:TTypeSymBracketOpen];
            node.xExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.yExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymRnd: {
            Maths0Node *node = [[Maths0Node alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
            return node;
        }
        default:
            // ignore
            break;
    }
    return nil;
}

@end
