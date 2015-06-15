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
#import "NSError+LowResCoder.h"

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

- (void)setError:(NSError *)error
{
    // don't overwrite existing error
    if (!_error)
    {
        _error = error;
    }
}

#pragma mark - Basics

- (Token *)nextToken
{
    if (self.currentTokenIndex + 1 < self.tokens.count)
    {
        return self.tokens[self.currentTokenIndex + 1];
    }
    return nil;
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
        self.error = [NSError programErrorWithCode:LRCErrorCodeParse
                                            reason:[NSString stringWithFormat:@"Expected %@", [Token stringForType:tokenType printable:YES]]
                                             token:self.token];
        return;
    }
}

- (void)acceptEol
{
    if (self.currentTokenIndex < self.tokens.count)
    {
        [self accept:TTypeSymEol];
    }
}

- (BOOL)acceptOptionalComma
{
    if (self.token.type == TTypeSymComma)
    {
        [self accept:TTypeSymComma];
        return YES;
    }
    return NO;
}

#pragma mark - Lines

- (NSArray *)acceptProgram
{
    NSMutableArray *nodes = [NSMutableArray array];
    while (self.currentTokenIndex < self.tokens.count)
    {
        Node *node = [self acceptCommandLine];
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
    while (self.currentTokenIndex < self.tokens.count && ([self isCommand] || [self isLabel] || self.token.type == TTypeSymEol))
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
    else if ([self isLabel])
    {
        node = [self acceptLabel];
    }
    else
    {
        node = [self acceptCommand];
        [self acceptEol];
    }
    return node;
}

- (Node *)acceptCommand
{
    Token *firstToken = self.token;
    Node *node;
    
    if ([self isImplicitLet])
    {
        node = [self acceptLet];
    }
    else switch (self.token.type)
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
        case TTypeSymDim:
            node = [self acceptDim];
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
        case TTypeSymEnd:
            node = [self acceptEnd];
            break;
        case TTypeSymGamepad:
            node = [self acceptGamepad];
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
        case TTypeSymBar:
            node = [self acceptBox];
            break;
        case TTypeSymScroll:
            node = [self acceptScroll];
            break;
        case TTypeSymText:
            node = [self acceptText];
            break;
        case TTypeSymData:
            node = [self acceptData];
            break;
        case TTypeSymRead:
            node = [self acceptRead];
            break;
        case TTypeSymRestore:
            node = [self acceptRestore];
            break;
        case TTypeSymWrite:
            node = [self acceptWrite];
            break;
        case TTypeSymOn:
            node = [self acceptOnEndGoto];
            break;
        case TTypeSymDef: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymSound)
            {
                node = [self acceptDefSound];
            }
            else
            {
                node = [self acceptDefSprite];
            }
            break;
        }
        case TTypeSymSprite: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymPalette)
            {
                node = [self acceptSpritePalette];
            }
            else if (next.type == TTypeSymOff)
            {
                node = [self acceptSpriteOff];
            }
            else
            {
                node = [self acceptSprite];
            }
            break;
        }
        case TTypeSymSound: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymOff)
            {
                node = [self acceptSoundOff];
            }
            else
            {
                node = [self acceptSound];
            }
            break;
        }
        case TTypeSymLayer:
            node = [self acceptLayer];
            break;
        case TTypeSymPaint:
            node = [self acceptPaint];
            break;
        case TTypeSymGet:
            node = [self acceptGet];
            break;
        case TTypeSymPut:
            node = [self acceptPut];
            break;
        default: {
            self.error = [NSError programErrorWithCode:LRCErrorCodeParse reason:@"Expected command" token:self.token];
            return nil;
        }
    }
    node.token = firstToken;
    return node;
}

- (BOOL)isCommand
{
    if ([self isImplicitLet])
    {
        return YES;
    }
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
        case TTypeSymBar:
        case TTypeSymScroll:
        case TTypeSymText:
        case TTypeSymGamepad:
        case TTypeSymData:
        case TTypeSymRead:
        case TTypeSymRestore:
        case TTypeSymWrite:
        case TTypeSymSprite:
        case TTypeSymSound:
        case TTypeSymLayer:
        case TTypeSymPaint:
        case TTypeSymGet:
        case TTypeSymPut:
            return YES;
        
        case TTypeSymEnd: {
            Token *next = [self nextToken];
            return (!next || next.type != TTypeSymIf);
        }
        
        case TTypeSymDef: {
            Token *next = [self nextToken];
            return (next.type == TTypeSymSprite || next.type == TTypeSymSound);
        }
            
        case TTypeSymOn: {
            Token *next = [self nextToken];
            return (next.type == TTypeSymEnd);
        }
        
        default:
            return NO;
    }
    return NO;
}

- (Node *)acceptLabel
{
    LabelNode *node = [[LabelNode alloc] init];
    node.token = self.token;
    node.identifier = self.token.attrString;
    [self accept:TTypeIdentifier];
    [self accept:TTypeSymColon];
    [self acceptEol];
    return node;
}

- (BOOL)isLabel
{
    return (self.token.type == TTypeIdentifier && [self nextToken].type == TTypeSymColon);
}

- (BOOL)isImplicitLet
{
    return (self.token.type == TTypeIdentifier && ([self nextToken].type == TTypeSymOpEq || [self nextToken].type == TTypeSymDollar || [self nextToken].type == TTypeSymBracketOpen));
}

#pragma mark - Commands

- (Node *)acceptPrint
{
    PrintNode *node = [[PrintNode alloc] init];
    [self accept:TTypeSymPrint];
    node.expression = [self acceptExpression];
    return node;
}

- (Node *)acceptGoto
{
    GotoNode *node = [[GotoNode alloc] init];
    [self accept:TTypeSymGoto];
    node.label = self.token.attrString;
    [self accept:TTypeIdentifier];
    return node;
}

- (Node *)acceptGosub
{
    GosubNode *node = [[GosubNode alloc] init];
    [self accept:TTypeSymGosub];
    node.label = self.token.attrString;
    [self accept:TTypeIdentifier];
    return node;
}

- (Node *)acceptReturn
{
    ReturnNode *node = [[ReturnNode alloc] init];
    [self accept:TTypeSymReturn];
    return node;
}

- (Node *)acceptLet
{
    LetNode *node = [[LetNode alloc] init];
    if (self.token.type == TTypeSymLet)
    {
        [self accept:TTypeSymLet];
    }
    node.variable = [self acceptVariable];
    [self accept:TTypeSymOpEq];
    node.expression = [self acceptExpression];
    return node;
}

- (Node *)acceptDim
{
    DimNode *node = [[DimNode alloc] init];
    [self accept:TTypeSymDim];
    node.variableNodes = [self acceptVariableList];
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
        [self acceptEol];
        node.commands = [self acceptCommandLines];
        BOOL blockClosed = NO;
        if (self.token.type == TTypeSymElse)
        {
            [self accept:TTypeSymElse];
            if (self.token.type == TTypeSymIf)
            {
                node.elseCommands = @[[self acceptIf]];
                blockClosed = YES;
            }
            else
            {
                [self acceptEol];
                node.elseCommands = [self acceptCommandLines];
            }
        }
        if (!blockClosed)
        {
            [self accept:TTypeSymEnd];
            [self accept:TTypeSymIf];
        }
    }
    else
    {
        // single line
        node.commands = @[[self acceptCommand]];
        if (self.token.type == TTypeSymElse)
        {
            [self accept:TTypeSymElse];
            node.elseCommands = @[[self acceptCommand]];
        }
    }
    return node;
}

- (Node *)acceptForNext
{
    ForNextNode *node = [[ForNextNode alloc] init];
    [self accept:TTypeSymFor];
    node.variable = [self acceptVariable];
    [self accept:TTypeSymOpEq];
    node.startExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.endExpression = [self acceptExpression];
    if (self.token.type == TTypeSymStep)
    {
        [self accept:TTypeSymStep];
        node.stepExpression = [self acceptExpression];
    }
    else
    {
        node.stepExpression = [[NumberNode alloc] initWithValue:1.0];
    }
    [self acceptEol];
    
    node.commands = [self acceptCommandLines];
    
    [self accept:TTypeSymNext];
    if (self.token.type == TTypeIdentifier)
    {
        node.matchingVariable = [self acceptVariable];
    }
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
    return node;
}

- (Node *)acceptDoLoop
{
    DoLoopNode *node = [[DoLoopNode alloc] init];
    [self accept:TTypeSymDo];
    [self acceptEol];
    
    node.commands = [self acceptCommandLines];
    
    [self accept:TTypeSymLoop];
    return node;
}

- (Node *)acceptExit
{
    ExitNode *node = [[ExitNode alloc] init];
    [self accept:TTypeSymExit];
    return node;
}

- (Node *)acceptWait
{
    WaitNode *node = [[WaitNode alloc] init];
    [self accept:TTypeSymWait];
    node.time = [self acceptExpression];
    if (self.token.type == TTypeSymTap)
    {
        node.tap = YES;
        [self accept:TTypeSymTap];
    }
    return node;
}

- (Node *)acceptEnd
{
    EndNode *node = [[EndNode alloc] init];
    [self accept:TTypeSymEnd];
    return node;
}

- (Node *)acceptGamepad
{
    GamepadNode *node = [[GamepadNode alloc] init];
    [self accept:TTypeSymGamepad];
    node.playersExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptColor
{
    ColorNode *node = [[ColorNode alloc] init];
    [self accept:TTypeSymColor];
    node.color = [self acceptExpression];
    return node;
}

- (Node *)acceptCls
{
    ClsNode *node = [[ClsNode alloc] init];
    [self accept:TTypeSymCls];
    node.color = [self acceptOptionalExpression];
    return node;
}

- (Node *)acceptPlot
{
    PlotNode *node = [[PlotNode alloc] init];
    [self accept:TTypeSymPlot];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
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
    return node;
}

- (Node *)acceptBox
{
    BoxNode *node = [[BoxNode alloc] init];
    node.fill = (self.token.type == TTypeSymBar);
    [self accept:self.token.type]; // box or bar
    node.fromXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.fromYExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.toXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.toYExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptScroll
{
    ScrollNode *node = [[ScrollNode alloc] init];
    [self accept:TTypeSymScroll];
    node.fromXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.fromYExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.toXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.toYExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.deltaXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.deltaYExpression = [self acceptExpression];
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
    return node;
}

- (Node *)acceptDefSprite
{
    DefSpriteNode *node = [[DefSpriteNode alloc] init];
    [self accept:TTypeSymDef];
    [self accept:TTypeSymSprite];
    node.imageExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.dataVariable = [self acceptVariable];
    return node;
}

- (Node *)acceptSpritePalette
{
    SpritePaletteNode *node = [[SpritePaletteNode alloc] init];
    [self accept:TTypeSymSprite];
    [self accept:TTypeSymPalette];
    node.nExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.color1Expression = [self acceptOptionalExpression];
    if ([self acceptOptionalComma])
    {
        node.color2Expression = [self acceptOptionalExpression];
        if ([self acceptOptionalComma])
        {
            node.color3Expression = [self acceptOptionalExpression];
        }
    }
    return node;
}

- (Node *)acceptSprite
{
    SpriteNode *node = [[SpriteNode alloc] init];
    [self accept:TTypeSymSprite];
    node.nExpression = [self acceptExpression];
    if ([self acceptOptionalComma])
    {
        node.xExpression = [self acceptOptionalExpression];
        if ([self acceptOptionalComma])
        {
            node.yExpression = [self acceptOptionalExpression];
            if ([self acceptOptionalComma])
            {
                node.imageExpression = [self acceptOptionalExpression];
            }
        }
    }
    return node;
}

- (Node *)acceptSpriteOff
{
    SpriteOffNode *node = [[SpriteOffNode alloc] init];
    [self accept:TTypeSymSprite];
    [self accept:TTypeSymOff];
    node.nExpression = [self acceptOptionalExpression];
    return node;
}

- (Node *)acceptData
{
    DataNode *node = [[DataNode alloc] init];
    [self accept:TTypeSymData];
    NSMutableArray *constants = [NSMutableArray array];
    BOOL more = NO;
    do
    {
        Node *constantNode;
        switch (self.token.type)
        {
            case TTypeSymOpMinus: {
                [self accept:TTypeSymOpMinus];
                constantNode = [[NumberNode alloc] initWithValue:-self.token.attrNumber];
                [self accept:TTypeNumber];
                break;
            }
            case TTypeSymOpPlus: {
                [self accept:TTypeSymOpPlus];
                constantNode = [[NumberNode alloc] initWithValue:self.token.attrNumber];
                [self accept:TTypeNumber];
                break;
            }
            case TTypeNumber: {
                constantNode = [[NumberNode alloc] initWithValue:self.token.attrNumber];
                [self accept:TTypeNumber];
                break;
            }
            case TTypeString: {
                constantNode = [[StringNode alloc] initWithValue:self.token.attrString];
                [self accept:TTypeString];
                break;
            }
            default: {
                self.error = [NSError programErrorWithCode:LRCErrorCodeParse reason:@"Expected constant" token:self.token];
                return nil;
            }
        }
        
        [constants addObject:constantNode];
        
        more = (self.token.type == TTypeSymComma);
        if (more)
        {
            [self accept:TTypeSymComma];
        }
    } while (more);
    
    node.constants = constants;
    
    return node;
}

- (Node *)acceptRead
{
    ReadNode *node = [[ReadNode alloc] init];
    [self accept:TTypeSymRead];
    node.variables = [self acceptVariableList];
    return node;
}

- (Node *)acceptRestore
{
    RestoreNode *node = [[RestoreNode alloc] init];
    [self accept:TTypeSymRestore];
    if (self.token.type == TTypeIdentifier)
    {
        node.label = self.token.attrString;
        [self accept:TTypeIdentifier];
    }
    return node;
}

- (Node *)acceptWrite
{
    WriteNode *node = [[WriteNode alloc] init];
    [self accept:TTypeSymWrite];
    if (self.token.type == TTypeSymClear)
    {
        [self accept:TTypeSymClear];
        node.clear = YES;
    }
    else
    {
        node.valueExpressions = [self acceptExpressionList];
    }
    return node;
}

- (Node *)acceptOnEndGoto
{
    OnEndGotoNode *node = [[OnEndGotoNode alloc] init];
    [self accept:TTypeSymOn];
    [self accept:TTypeSymEnd];
    if (self.token.type == TTypeSymGoto)
    {
        [self accept:TTypeSymGoto];
        node.label = self.token.attrString;
        [self accept:TTypeIdentifier];
    }
    return node;
}

- (Node *)acceptDefSound
{
    [self accept:TTypeSymDef];
    [self accept:TTypeSymSound];
    if (self.token.type == TTypeSymLine)
    {
        [self accept:TTypeSymLine];
        DefSoundLineNode *node = [[DefSoundLineNode alloc] init];
        node.nExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.bendTimeExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.pitchBendExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.pulseBendExpression = [self acceptExpression];
        return node;
    }
    else
    {
        DefSoundNode *node = [[DefSoundNode alloc] init];
        node.nExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.waveExpression = [self acceptExpression];
        if ([self acceptOptionalComma])
        {
            node.pulseWidthExpression = [self acceptExpression];
            if ([self acceptOptionalComma])
            {
                node.maxTimeExpression = [self acceptExpression];
            }
        }
        return node;
    }
    return nil;
}

- (Node *)acceptSound
{
    SoundNode *node = [[SoundNode alloc] init];
    [self accept:TTypeSymSound];
    node.voiceExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.pitchExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.durationExpression = [self acceptExpression];
    if ([self acceptOptionalComma])
    {
        node.defExpression = [self acceptOptionalExpression];
    }
    return node;
}

- (Node *)acceptSoundOff
{
    SoundOffNode *node = [[SoundOffNode alloc] init];
    [self accept:TTypeSymSound];
    [self accept:TTypeSymOff];
    node.voiceExpression = [self acceptOptionalExpression];
    return node;
}

- (Node *)acceptLayer
{
    LayerNode *node = [[LayerNode alloc] init];
    [self accept:TTypeSymLayer];
    node.nExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptPaint
{
    PaintNode *node = [[PaintNode alloc] init];
    [self accept:TTypeSymPaint];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptGet
{
    GetNode *node = [[GetNode alloc] init];
    [self accept:TTypeSymGet];
    node.fromXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.fromYExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.toXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.toYExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptPut
{
    PutNode *node = [[PutNode alloc] init];
    [self accept:TTypeSymPut];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
    if (self.token.type == TTypeSymComma)
    {
        [self accept:TTypeSymComma];
        node.srcXExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.srcYExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.srcWidthExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.srcHeightExpression = [self acceptExpression];
    }
    return node;
}

#pragma mark - Expressions

- (Node *)acceptExpression
{
    return [self acceptExpressionLevel:0];
}

- (Node *)acceptOptionalExpression
{
    if (self.token.type == TTypeSymComma || self.token.type == TTypeSymEol || self.token.type == TTypeSymElse)
    {
        return nil;
    }
    return [self acceptExpression];
}

- (Node *)acceptExpressionLevel:(int)level
{
    static NSArray *operatorLevels = nil;
    if (!operatorLevels)
    {
        operatorLevels = @[
                           @[@(TTypeSymOpXor)],
                           @[@(TTypeSymOpOr)],
                           @[@(TTypeSymOpAnd)],
                           @[@(TTypeSymOpEq), @(TTypeSymOpUneq), @(TTypeSymOpGr), @(TTypeSymOpLe), @(TTypeSymOpGrEq), @(TTypeSymOpLeEq)],
                           @[@(TTypeSymOpPlus), @(TTypeSymOpMinus)],
                           @[@(TTypeSymOpMod)],
                           @[@(TTypeSymOpMul), @(TTypeSymOpDiv)],
                           @[@(TTypeSymOpPow)]
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
        newNode.token = self.token;
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
        node.token = self.token;
        node.type = self.token.type;
        [self accept:self.token.type];
        node.expression = [self acceptUnaryExpression];
        return node;
    }
    return [self acceptPrimaryExpression];
}

- (Node *)acceptPrimaryExpression
{
    Token *firstToken = self.token;
    Node *primaryNode = [self acceptFunction];
    if (!primaryNode)
    {
        switch (self.token.type)
        {
            case TTypeIdentifier: {
                primaryNode = [self acceptVariable];
                break;
            }
            case TTypeNumber: {
                primaryNode = [[NumberNode alloc] initWithValue:self.token.attrNumber];
                [self accept:TTypeNumber];
                break;
            }
            case TTypeString: {
                primaryNode = [[StringNode alloc] initWithValue:self.token.attrString];
                [self accept:TTypeString];
                break;
            }
            case TTypeSymBracketOpen: {
                primaryNode = [self acceptExpressionBlock];
                break;
            }
            case TTypeSymTrue: {
                primaryNode = [[NumberNode alloc] initWithValue:-1];
                [self accept:TTypeSymTrue];
                break;
            }
            case TTypeSymFalse: {
                primaryNode = [[NumberNode alloc] initWithValue:0];
                [self accept:TTypeSymFalse];
                break;
            }
            case TTypeSymPi: {
                primaryNode = [[NumberNode alloc] initWithValue:M_PI];
                [self accept:TTypeSymPi];
                break;
            }
            default: {
                self.error = [NSError programErrorWithCode:LRCErrorCodeParse reason:@"Expected expression" token:self.token];
                return nil;
            }
        }
    }
    primaryNode.token = firstToken;
    return primaryNode;
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
        case TTypeSymRight: {
            DirectionPadNode *node = [[DirectionPadNode alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
            [self accept:TTypeSymBracketOpen];
            node.portExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymButton: {
            ButtonNode *node = [[ButtonNode alloc] init];
            [self accept:TTypeSymButton];
            if (self.token.type == TTypeSymTap)
            {
                [self accept:TTypeSymTap];
                node.tap = YES;
            }
            [self accept:TTypeSymBracketOpen];
            node.portExpression = [self acceptExpression];
            if (self.token.type == TTypeSymComma)
            {
                [self accept:TTypeSymComma];
                node.buttonExpression = [self acceptExpression];
            }
            else
            {
                node.buttonExpression = [[NumberNode alloc] initWithValue:0];
            }
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
        case TTypeSymText: {
            TextWidthNode *node = [[TextWidthNode alloc] init];
            [self accept:TTypeSymText];
            [self accept:TTypeSymWidth];
            [self accept:TTypeSymBracketOpen];
            node.valueExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymSprite: {
            [self accept:TTypeSymSprite];
            if (self.token.type == TTypeSymHit)
            {
                SpriteHitNode *node = [[SpriteHitNode alloc] init];
                [self accept:TTypeSymHit];
                [self accept:TTypeSymBracketOpen];
                node.nExpression = [self acceptExpression];
                if (self.token.type == TTypeSymComma)
                {
                    [self accept:TTypeSymComma];
                    node.otherNExpression = [self acceptExpression];
                    if (self.token.type == TTypeSymTo)
                    {
                        [self accept:TTypeSymTo];
                        node.lastNExpression = [self acceptExpression];
                    }
                }
                [self accept:TTypeSymBracketClose];
                return node;
            }
            else
            {
                SpriteValueNode *node = [[SpriteValueNode alloc] init];
                NSString *type = self.token.attrString;
                [self accept:TTypeIdentifier];
                node.type = [type characterAtIndex:0];
                if (node.type != 'X' && node.type != 'Y' && node.type != 'I')
                {
                    self.error = [NSError programErrorWithCode:LRCErrorCodeParse
                                                        reason:[NSString stringWithFormat:@"Unexpected %@", type]
                                                         token:self.token];
                    return nil;

                }
                [self accept:TTypeSymBracketOpen];
                node.nExpression = [self acceptExpression];
                [self accept:TTypeSymBracketClose];
                return node;
            }
        }
        case TTypeSymHit:
        case TTypeSymRnd: {
            Maths0Node *node = [[Maths0Node alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
            return node;
        }
        case TTypeSymAbs:
        case TTypeSymAtn:
        case TTypeSymCos:
        case TTypeSymExp:
        case TTypeSymInt:
        case TTypeSymLog:
        case TTypeSymSgn:
        case TTypeSymSin:
        case TTypeSymSqr:
        case TTypeSymTan: {
            Maths1Node *node = [[Maths1Node alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
            [self accept:TTypeSymBracketOpen];
            node.xExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }

        case TTypeSymLeftS: {
            LeftSNode *node = [[LeftSNode alloc] init];
            [self accept:TTypeSymLeftS];
            [self accept:TTypeSymBracketOpen];
            node.stringExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.numberExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymRightS: {
            RightSNode *node = [[RightSNode alloc] init];
            [self accept:TTypeSymRightS];
            [self accept:TTypeSymBracketOpen];
            node.stringExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.numberExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymMid: {
            MidNode *node = [[MidNode alloc] init];
            [self accept:TTypeSymMid];
            [self accept:TTypeSymBracketOpen];
            node.stringExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.positionExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.numberExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymInstr: {
            InstrNode *node = [[InstrNode alloc] init];
            [self accept:TTypeSymInstr];
            [self accept:TTypeSymBracketOpen];
            node.stringExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.searchExpression = [self acceptExpression];
            if (self.token.type == TTypeSymComma)
            {
                [self accept:TTypeSymComma];
                node.positionExpression = [self acceptExpression];
            }
            else
            {
                node.positionExpression = [[NumberNode alloc] initWithValue:1.0];
            }
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymChr: {
            ChrNode *node = [[ChrNode alloc] init];
            [self accept:TTypeSymChr];
            [self accept:TTypeSymBracketOpen];
            node.asciiExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymAsc: {
            AscNode *node = [[AscNode alloc] init];
            [self accept:TTypeSymAsc];
            [self accept:TTypeSymBracketOpen];
            node.stringExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymLen: {
            LenNode *node = [[LenNode alloc] init];
            [self accept:TTypeSymLen];
            [self accept:TTypeSymBracketOpen];
            node.stringExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymVal: {
            ValNode *node = [[ValNode alloc] init];
            [self accept:TTypeSymVal];
            [self accept:TTypeSymBracketOpen];
            node.stringExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymStr: {
            StrNode *node = [[StrNode alloc] init];
            [self accept:TTypeSymStr];
            [self accept:TTypeSymBracketOpen];
            node.numberExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymHex: {
            HexNode *node = [[HexNode alloc] init];
            [self accept:TTypeSymHex];
            [self accept:TTypeSymBracketOpen];
            node.numberExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        default:
            // ignore
            break;
    }
    return nil;
}

- (VariableNode *)acceptVariable
{
    VariableNode *node = [[VariableNode alloc] init];
    node.token = self.token;
    node.identifier = self.token.attrString;
    [self accept:TTypeIdentifier];
    if (self.token.type == TTypeSymDollar)
    {
        // is string
        [self accept:TTypeSymDollar];
        node.isString = YES;
    }
    if (self.token.type == TTypeSymBracketOpen)
    {
        // is array variable
        [self accept:TTypeSymBracketOpen];
        NSMutableArray *indexExpressions = [NSMutableArray array];
        BOOL more = NO;
        do
        {
            Node *indexExpression = [self acceptExpression];
            [indexExpressions addObject:indexExpression];
            more = (self.token.type == TTypeSymComma);
            if (more)
            {
                [self accept:TTypeSymComma];
            }
        } while (more);
        [self accept:TTypeSymBracketClose];
        node.indexExpressions = indexExpressions;
    }
    return node;
}

- (NSArray *)acceptVariableList
{
    NSMutableArray *variables = [NSMutableArray array];
    BOOL more = NO;
    do
    {
        VariableNode *variable = [self acceptVariable];
        [variables addObject:variable];
        more = (self.token.type == TTypeSymComma);
        if (more)
        {
            [self accept:TTypeSymComma];
        }
    } while (more);
    return variables;
}

- (NSArray *)acceptExpressionList
{
    NSMutableArray *expressions = [NSMutableArray array];
    BOOL more = NO;
    do
    {
        Node *expression = [self acceptExpression];
        [expressions addObject:expression];
        more = (self.token.type == TTypeSymComma);
        if (more)
        {
            [self accept:TTypeSymComma];
        }
    } while (more);
    return expressions;
}

@end
