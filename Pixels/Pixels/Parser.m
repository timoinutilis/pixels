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
    }
}

- (void)accept:(TType)tokenType1 and:(TType)tokenType2
{
    Token *errorToken;
    if (self.token.type != tokenType1)
    {
        errorToken = self.token;
    }
    else
    {
        [self accept:tokenType1];
        if (self.token.type != tokenType2)
        {
            errorToken = self.token;
        }
        else
        {
            [self accept:tokenType2];
        }
    }
    
    if (errorToken)
    {
        self.error = [NSError programErrorWithCode:LRCErrorCodeParse
                                            reason:[NSString stringWithFormat:@"Expected %@ %@", [Token stringForType:tokenType1 printable:YES], [Token stringForType:tokenType2 printable:YES]]
                                             token:errorToken];
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

- (BOOL)tokenIsParameter
{
    return self.token.type != TTypeSymComma && self.token.type != TTypeSymEol && self.token.type != TTypeSymElse;
}

#pragma mark - Lines

- (NSArray *)acceptProgram
{
    NSMutableArray *nodes = [NSMutableArray array];
    while (self.currentTokenIndex < self.tokens.count)
    {
        Node *node = [self acceptCommandLine];
        if (self.error)
        {
            return nil;
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
    while (self.currentTokenIndex < self.tokens.count && ([self isCommand] || [self isLabel] || self.token.type == TTypeSymEol))
    {
        Node *node = [self acceptCommandLine];
        if (self.error)
        {
            return nil;
        }
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
        case TTypeSymInput:
            node = [self acceptInput];
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
        case TTypeSymPersist:
            node = [self acceptPersist];
            break;
        case TTypeSymSwap:
            node = [self acceptSwap];
            break;
        case TTypeSymRandomize:
            node = [self acceptRandomize];
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
        case TTypeSymWait: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymButton)
            {
                node = [self acceptWaitButton];
            }
            else
            {
                node = [self acceptWait];
            }
            break;
        }
        case TTypeSymEnd:
            node = [self acceptEnd];
            break;
        case TTypeSymGamepad:
            node = [self acceptGamepad];
            break;
        case TTypeSymDisplay:
            node = [self acceptDisplay];
            break;
        case TTypeSymLayer: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymOpen)
            {
                node = [self acceptLayerOpen];
            }
            else if (next.type == TTypeSymClose)
            {
                node = [self acceptLayerClose];
            }
            else if (next.type == TTypeSymDisplay)
            {
                node = [self acceptLayerDisplay];
            }
            else if (next.type == TTypeSymOffset)
            {
                node = [self acceptLayerOffset];
            }
            else if (next.type == TTypeSymOff)
            {
                node = [self acceptLayerOff];
            }
            else if (next.type == TTypeSymOn)
            {
                node = [self acceptLayerOn];
            }
            else
            {
                node = [self acceptLayer];
            }
            break;
        }
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
        case TTypeSymCircle:
            node = [self acceptCircle];
            break;
        case TTypeSymScroll:
            node = [self acceptScroll];
            break;
        case TTypeSymText:
            node = [self acceptText];
            break;
        case TTypeSymFont:
            node = [self acceptFont];
            break;
        case TTypeSymPalette:
            node = [self acceptPalette];
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
        case TTypeSymWrite: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymDim)
            {
                node = [self acceptWriteDim];
            }
            else if (next.type == TTypeSymWidth)
            {
                node = [self acceptWriteWidth];
            }
            else
            {
                node = [self acceptWrite];
            }
            break;
        }
        case TTypeSymOn:
            node = [self acceptOnXGoto];
            break;
        case TTypeSymDef: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymSound)
            {
                node = [self acceptDefSound];
            }
            else if (next.type == TTypeSymSprite)
            {
                node = [self acceptDefSprite];
            }
            else
            {
                self.error = [NSError unexpectedTokenErrorWithToken:next];
                return nil;
            }
            break;
        }
        case TTypeSymSprite: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymPalette)
            {
                node = [self acceptSpritePalette];
            }
            else if (next.type == TTypeSymZoom)
            {
                node = [self acceptSpriteZoom];
            }
            else if (next.type == TTypeSymOff)
            {
                node = [self acceptSpriteOff];
            }
            else if (next.type == TTypeSymLayer)
            {
                node = [self acceptSpriteLayer];
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
            else if (next.type == TTypeSymWait)
            {
                node = [self acceptSoundWait];
            }
            else if (next.type == TTypeSymResume)
            {
                node = [self acceptSoundResume];
            }
            else
            {
                node = [self acceptSound];
            }
            break;
        }
        case TTypeSymPaint:
            node = [self acceptPaint];
            break;
        case TTypeSymGet: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymBlock)
            {
                node = [self acceptGetBlock];
            }
            else
            {
                node = [self acceptGet]; // obsolete
            }
            break;
        }
        case TTypeSymPut: {
            Token *next = [self nextToken];
            if (next.type == TTypeSymBlock)
            {
                node = [self acceptPutBlock];
            }
            else
            {
                node = [self acceptPut]; // obsolete
            }
            break;
        }
        case TTypeSymLeftS:
            node = [self acceptLeftS];
            break;
        case TTypeSymRightS:
            node = [self acceptRightS];
            break;
        case TTypeSymMid:
            node = [self acceptMid];
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
        case TTypeSymDim:
        case TTypeSymWhile:
        case TTypeSymRepeat:
        case TTypeSymDo:
        case TTypeSymExit:
        case TTypeSymPersist:
        case TTypeSymSwap:
        case TTypeSymWait:
        case TTypeSymDisplay:
        case TTypeSymColor:
        case TTypeSymCls:
        case TTypeSymPlot:
        case TTypeSymLine:
        case TTypeSymBox:
        case TTypeSymBar:
        case TTypeSymCircle:
        case TTypeSymScroll:
        case TTypeSymText:
        case TTypeSymFont:
        case TTypeSymGamepad:
        case TTypeSymData:
        case TTypeSymRead:
        case TTypeSymRestore:
        case TTypeSymWrite:
        case TTypeSymOn:
        case TTypeSymDef:
        case TTypeSymSprite:
        case TTypeSymSound:
        case TTypeSymLayer:
        case TTypeSymPaint:
        case TTypeSymGet:
        case TTypeSymPut:
        case TTypeSymPalette:
        case TTypeSymRandomize:
        case TTypeSymLeftS:
        case TTypeSymRightS:
        case TTypeSymMid:
            return YES;
        
        case TTypeSymEnd: {
            Token *next = [self nextToken];
            return (!next || next.type != TTypeSymIf);
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

- (Node *)acceptInput
{
    InputNode *node = [[InputNode alloc] init];
    [self accept:TTypeSymInput];
    node.expression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.variable = [self acceptVariable];
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
    
    if ([self tokenIsParameter])
    {
        node.label = self.token.attrString;
        [self accept:TTypeIdentifier];
    }
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
    if (self.token.type == TTypeSymPersist)
    {
        [self accept:TTypeSymPersist];
        node.persist = YES;
    }
    node.variableNodes = [self acceptVariableList];
    return node;
}

- (Node *)acceptPersist
{
    PersistNode *node = [[PersistNode alloc] init];
    [self accept:TTypeSymPersist];
    node.variableNodes = [self acceptVariableList];
    return node;
}

- (Node *)acceptSwap
{
    SwapNode *node = [[SwapNode alloc] init];
    [self accept:TTypeSymSwap];
    node.variable1 = [self acceptVariable];
    [self accept:TTypeSymComma];
    node.variable2 = [self acceptVariable];
    return node;
}

- (Node *)acceptRandomize
{
    RandomizeNode *node = [[RandomizeNode alloc] init];
    [self accept:TTypeSymRandomize];
    node.expression = [self acceptExpression];
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
                Node *elseCommand = [self acceptIf];
                if (elseCommand)
                {
                    node.elseCommands = @[elseCommand];
                }
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
            [self accept:TTypeSymEnd and:TTypeSymIf];
        }
    }
    else
    {
        // single line
        Node *command = [self acceptCommand];
        if (command)
        {
            node.commands = @[command];
        }
        if (self.token.type == TTypeSymElse)
        {
            [self accept:TTypeSymElse];
            Node *elseCommand = [self acceptCommand];
            if (elseCommand)
            {
                node.elseCommands = @[elseCommand];
            }
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

- (Node *)acceptWaitButton
{
    WaitButtonNode *node = [[WaitButtonNode alloc] init];
    [self accept:TTypeSymWait and:TTypeSymButton];
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

- (Node *)acceptDisplay
{
    DisplayNode *node = [[DisplayNode alloc] init];
    [self accept:TTypeSymDisplay];
    node.modeExpression = [self acceptExpression];
    if (self.token.type == TTypeSymShared)
    {
        [self accept:TTypeSymShared];
        node.sharedPalette = YES;
    }
    return node;
}

- (Node *)acceptLayerOpen
{
    LayerOpenNode *node = [[LayerOpenNode alloc] init];
    [self accept:TTypeSymLayer and:TTypeSymOpen];
    node.nExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.widthExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.heightExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.renderModeExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptLayerClose
{
    LayerCloseNode *node = [[LayerCloseNode alloc] init];
    [self accept:TTypeSymLayer and:TTypeSymClose];
    node.nExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptLayerOffset
{
    LayerOffsetNode *node = [[LayerOffsetNode alloc] init];
    [self accept:TTypeSymLayer and:TTypeSymOffset];
    node.nExpression = [self acceptExpression];
    if ([self acceptOptionalComma])
    {
        node.xExpression = [self acceptOptionalExpression];
        if ([self acceptOptionalComma])
        {
            node.yExpression = [self acceptOptionalExpression];
        }
    }
    return node;
}

- (Node *)acceptLayerDisplay
{
    LayerDisplayNode *node = [[LayerDisplayNode alloc] init];
    [self accept:TTypeSymLayer and:TTypeSymDisplay];
    node.nExpression = [self acceptExpression];
    if ([self acceptOptionalComma])
    {
        node.xExpression = [self acceptOptionalExpression];
        if ([self acceptOptionalComma])
        {
            node.yExpression = [self acceptOptionalExpression];
            if ([self acceptOptionalComma])
            {
                node.widthExpression = [self acceptOptionalExpression];
                if ([self acceptOptionalComma])
                {
                    node.heightExpression = [self acceptOptionalExpression];
                }
            }
        }
    }
    return node;
}

- (Node *)acceptLayerOff
{
    LayerOnOffNode *node = [[LayerOnOffNode alloc] init];
    [self accept:TTypeSymLayer and:TTypeSymOff];
    node.nExpression = [self acceptExpression];
    node.visible = NO;
    return node;
}

- (Node *)acceptLayerOn
{
    LayerOnOffNode *node = [[LayerOnOffNode alloc] init];
    [self accept:TTypeSymLayer and:TTypeSymOn];
    node.nExpression = [self acceptExpression];
    node.visible = YES;
    return node;
}

- (Node *)acceptLayer
{
    LayerNode *node = [[LayerNode alloc] init];
    [self accept:TTypeSymLayer];
    node.nExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptColor
{
    ColorNode *node = [[ColorNode alloc] init];
    [self accept:TTypeSymColor];
    node.color = [self acceptOptionalExpression];
    if ([self acceptOptionalComma])
    {
        node.bgColor = [self acceptOptionalExpression];
        if ([self acceptOptionalComma])
        {
            node.borderColor = [self acceptOptionalExpression];
        }
    }
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

- (Node *)acceptCircle
{
    CircleNode *node = [[CircleNode alloc] init];
    [self accept:TTypeSymCircle];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.radiusXExpression = [self acceptExpression];
    if ([self acceptOptionalComma])
    {
        node.radiusYExpression = [self acceptExpression];
    }
    if (self.token.type == TTypeSymPaint)
    {
        [self accept:TTypeSymPaint];
        node.fill = YES;
    }
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
    if (self.token.type == TTypeSymClear)
    {
        [self accept:TTypeSymClear];
        node.refill = YES;
    }
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
    if ([self acceptOptionalComma])
    {
        node.alignExpression = [self acceptExpression];
        if ([self acceptOptionalComma])
        {
            node.outlineExpression = [self acceptExpression];
        }
    }
    return node;
}

- (Node *)acceptFont
{
    FontNode *node = [[FontNode alloc] init];
    [self accept:TTypeSymFont];
    node.fontExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptPalette
{
    PaletteNode *node = [[PaletteNode alloc] init];
    [self accept:TTypeSymPalette];
    if (self.token.type == TTypeSymClear)
    {
        node.clear = YES;
        [self accept:TTypeSymClear];
    }
    else
    {
        node.nExpression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.valueExpression = [self acceptExpression];
    }
    return node;
}

- (Node *)acceptDefSprite
{
    DefSpriteNode *node = [[DefSpriteNode alloc] init];
    [self accept:TTypeSymDef and:TTypeSymSprite];
    node.imageExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.dataVariable = [self acceptVariable];
    if ([self acceptOptionalComma])
    {
        node.color1Expression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.color2Expression = [self acceptExpression];
        [self accept:TTypeSymComma];
        node.color3Expression = [self acceptExpression];
    }
    
    return node;
}

- (Node *)acceptSpritePalette
{
    SpritePaletteNode *node = [[SpritePaletteNode alloc] init];
    [self accept:TTypeSymSprite and:TTypeSymPalette];
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

- (Node *)acceptSpriteZoom
{
    SpriteScaleNode *node = [[SpriteScaleNode alloc] init];
    [self accept:TTypeSymSprite and:TTypeSymZoom];
    node.nExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
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
    [self accept:TTypeSymSprite and:TTypeSymOff];
    node.nExpression = [self acceptOptionalExpression];
    return node;
}

- (Node *)acceptSpriteLayer
{
    SpriteLayerNode *node = [[SpriteLayerNode alloc] init];
    [self accept:TTypeSymSprite and:TTypeSymLayer];
    node.layerExpression = [self acceptExpression];
    if (self.token.type == TTypeSymComma)
    {
        [self accept:TTypeSymComma];
        node.spriteFromExpression = [self acceptExpression];
        if (self.token.type == TTypeSymTo)
        {
            [self accept:TTypeSymTo];
            node.spriteToExpression = [self acceptExpression];
        }
    }

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
        
        if (self.error)
        {
            return nil;
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

- (Node *)acceptWriteDim
{
    [self accept:TTypeSymWrite and:TTypeSymDim];
    WriteDimNode *node = [[WriteDimNode alloc] init];
    node.variable = [self acceptVariable];
    if ([self acceptOptionalComma])
    {
        node.columnsExpression = [self acceptExpression];
    }
    return node;
}

- (Node *)acceptWriteWidth
{
    WriteWidthNode *node = [[WriteWidthNode alloc] init];
    [self accept:TTypeSymWrite and:TTypeSymWidth];
    node.columnsExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptOnXGoto
{
    OnXGotoNode *node = [[OnXGotoNode alloc] init];

    [self accept:TTypeSymOn];
    if (self.token.type != TTypeSymEnd && self.token.type != TTypeSymPause)
    {
        self.error = [NSError unexpectedTokenErrorWithToken:self.token];
        return nil;
    }
    node.xType = self.token.type;
    [self accept:node.xType];
    
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
    [self accept:TTypeSymDef and:TTypeSymSound];
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
    [self accept:TTypeSymSound and:TTypeSymOff];
    node.voiceExpression = [self acceptOptionalExpression];
    return node;
}

- (Node *)acceptSoundWait
{
    SoundWaitNode *node = [[SoundWaitNode alloc] init];
    [self accept:TTypeSymSound and:TTypeSymWait];
    return node;
}

- (Node *)acceptSoundResume
{
    SoundResumeNode *node = [[SoundResumeNode alloc] init];
    [self accept:TTypeSymSound and:TTypeSymResume];
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
        Node *expression = [self acceptExpression]; // parameter can have two meanings
        if (self.token.type == TTypeSymComma)
        {
            // PUT with source rectangle
            node.srcXExpression = expression;
            [self accept:TTypeSymComma];
            node.srcYExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.srcWidthExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.srcHeightExpression = [self acceptExpression];
            if (self.token.type == TTypeSymComma)
            {
                // optional transparency
                [self accept:TTypeSymComma];
                node.transparencyExpression = [self acceptExpression];
            }
        }
        else
        {
            // PUT with transparency but without source rectangle
            node.transparencyExpression = expression;
        }
    }
    return node;
}

- (Node *)acceptGetBlock
{
    GetBlockNode *node = [[GetBlockNode alloc] init];
    [self accept:TTypeSymGet and:TTypeSymBlock];
    node.nExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.fromXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.fromYExpression = [self acceptExpression];
    [self accept:TTypeSymTo];
    node.toXExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.toYExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptPutBlock
{
    PutBlockNode *node = [[PutBlockNode alloc] init];
    [self accept:TTypeSymPut and:TTypeSymBlock];
    node.nExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.xExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.yExpression = [self acceptExpression];
    if ([self acceptOptionalComma])
    {
        node.maskExpression = [self acceptExpression];
    }
    return node;
}

- (Node *)acceptLeftS
{
    LeftSCommandNode *node = [[LeftSCommandNode alloc] init];
    [self accept:TTypeSymLeftS];
    [self accept:TTypeSymBracketOpen];
    node.stringVariable = [self acceptVariable];
    [self accept:TTypeSymComma];
    node.numberExpression = [self acceptExpression];
    [self accept:TTypeSymBracketClose];
    [self accept:TTypeSymOpEq];
    node.srcStringExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptRightS
{
    RightSCommandNode *node = [[RightSCommandNode alloc] init];
    [self accept:TTypeSymRightS];
    [self accept:TTypeSymBracketOpen];
    node.stringVariable = [self acceptVariable];
    [self accept:TTypeSymComma];
    node.numberExpression = [self acceptExpression];
    [self accept:TTypeSymBracketClose];
    [self accept:TTypeSymOpEq];
    node.srcStringExpression = [self acceptExpression];
    return node;
}

- (Node *)acceptMid
{
    MidCommandNode *node = [[MidCommandNode alloc] init];
    [self accept:TTypeSymMid];
    [self accept:TTypeSymBracketOpen];
    node.stringVariable = [self acceptVariable];
    [self accept:TTypeSymComma];
    node.positionExpression = [self acceptExpression];
    [self accept:TTypeSymComma];
    node.numberExpression = [self acceptExpression];
    [self accept:TTypeSymBracketClose];
    [self accept:TTypeSymOpEq];
    node.srcStringExpression = [self acceptExpression];
    return node;
}

#pragma mark - Expressions

- (Node *)acceptExpression
{
    return [self acceptExpressionLevel:0];
}

- (Node *)acceptOptionalExpression
{
    if ([self tokenIsParameter])
    {
        return [self acceptExpression];
    }
    return nil;
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
        if (self.error)
        {
            return nil;
        }
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
            [self accept:TTypeSymText and:TTypeSymWidth];
            [self accept:TTypeSymBracketOpen];
            node.valueExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymPalette: {
            PaletteFuncNode *node = [[PaletteFuncNode alloc] init];
            [self accept:TTypeSymPalette];
            [self accept:TTypeSymBracketOpen];
            node.nExpression = [self acceptExpression];
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
        case TTypeSymLayer: {
            LayerHitNode *node = [[LayerHitNode alloc] init];
            [self accept:TTypeSymLayer and:TTypeSymHit];
            [self accept:TTypeSymBracketOpen];
            node.layerExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.spriteExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }
        case TTypeSymHit:
        case TTypeSymRnd:
        case TTypeSymTimer: {
            Maths0Node *node = [[Maths0Node alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
            return node;
        }
        case TTypeSymSound: {
            [self accept:TTypeSymSound];
            if (self.token.type == TTypeSymEnd)
            {
                SoundEndNode *node = [[SoundEndNode alloc] init];
                [self accept:TTypeSymEnd];
                if (self.token.type == TTypeSymBracketOpen)
                {
                    [self accept:TTypeSymBracketOpen];
                    node.voiceExpression = [self acceptExpression];
                    [self accept:TTypeSymBracketClose];
                }
                return node;
            }
            else
            {
                SoundLenNode *node = [[SoundLenNode alloc] init];
                [self accept:TTypeSymLen];
                if (self.token.type == TTypeSymBracketOpen)
                {
                    [self accept:TTypeSymBracketOpen];
                    node.voiceExpression = [self acceptExpression];
                    [self accept:TTypeSymBracketClose];
                }
                return node;
            }
            break;
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

        case TTypeSymMin:
        case TTypeSymMax: {
            Maths2Node *node = [[Maths2Node alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
            [self accept:TTypeSymBracketOpen];
            node.xExpression = [self acceptExpression];
            [self accept:TTypeSymComma];
            node.yExpression = [self acceptExpression];
            [self accept:TTypeSymBracketClose];
            return node;
        }

        case TTypeSymDate:
        case TTypeSymTime: {
            String0Node *node = [[String0Node alloc] init];
            node.type = self.token.type;
            [self accept:self.token.type];
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
            if (self.error)
            {
                return nil;
            }
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
        if (self.error)
        {
            return nil;
        }
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
        if (self.error)
        {
            return nil;
        }
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
