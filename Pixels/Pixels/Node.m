//
//  Node.m
//  Pixels
//
//  Created by Timo Kloss on 22/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Node.h"
#import "Runner.h"
#import "Renderer.h"
#import "ProgramException.h"

NSString *const TRANSFER = @"TRANSFER";

@implementation Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
}

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass canBeString:(BOOL)canBeString
{
    if (pass == PrePassCheckSemantic && !canBeString && self.returnsString)
    {
        @throw [ProgramException typeMismatchExceptionWithNode:self];
    }
    [self prepareWithRunnable:runnable pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    return nil;
}

- (NSNumber *)evaluateNumberWithRunner:(Runner *)runner min:(int)min max:(int)max
{
    NSNumber *number = [self evaluateWithRunner:runner];
    if (number.intValue < min || number.intValue > max)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:number.intValue];
    }
    return number;
}

- (void)endOfLoopWithRunner:(Runner *)runner
{
}

- (BOOL)returnsString
{
    return NO;
}

@end



// Variables/Constants

@implementation NumberNode

- (instancetype)initWithValue:(float)value
{
    if (self = [super init])
    {
        self.value = value;
    }
    return self;
}

- (id)evaluateWithRunner:(Runner *)runner
{
    return @(self.value);
}

@end



@implementation StringNode

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init])
    {
        self.value = value;
    }
    return self;
}

- (id)evaluateWithRunner:(Runner *)runner
{
    return self.value;
}

- (BOOL)returnsString
{
    return YES;
}

@end



@implementation VariableNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    for (Node *expression in self.indexExpressions)
    {
        [expression prepareWithRunnable:runnable pass:pass canBeString:NO];
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    return [runner valueOfVariable:self];
}

- (BOOL)returnsString
{
    return self.isString;
}

- (NSArray *)indexesWithRunner:(Runner *)runner add:(int)addValue
{
    NSMutableArray *indexes = [NSMutableArray array];
    for (Node *expressionNode in self.indexExpressions)
    {
        NSNumber *indexNumber = [expressionNode evaluateWithRunner:runner];
        if (addValue != 0)
        {
            indexNumber = @(indexNumber.intValue + addValue);
        }
        [indexes addObject:indexNumber];
    }
    return indexes;
}

@end



@implementation LabelNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassInit)
    {
        runnable.labels[self.identifier] = self;
        
        // labels are needed for data too!
        [runnable.dataNodes addObject:self];
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner next];
    return nil;
}

@end



// Commands

@implementation IfNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.condition prepareWithRunnable:runnable pass:pass canBeString:NO];
    [runnable prepareNodes:self.commands pass:pass];
    [runnable prepareNodes:self.elseCommands pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *value = [self.condition evaluateWithRunner:runner];
    if (value.intValue == 0)
    {
        if (self.elseCommands)
        {
            [runner addSequenceWithNodes:self.elseCommands isLoop:NO parent:self];
        }
        else
        {
            [runner next];
        }
    }
    else
    {
        [runner addSequenceWithNodes:self.commands isLoop:NO parent:self];
    }
    return nil;
}

@end



@implementation GotoNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassCheckSemantic)
    {
        if (!runnable.labels[self.label])
        {
            NSException *exception = [ProgramException exceptionWithName:@"UndefinedLabel"
                                                                  reason:[NSString stringWithFormat:@"Undefined label %@", self.label]
                                                                   token:self.token];
            @throw exception;
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner gotoLabel:self.label isGosub:NO atToken:self.token];
    return nil;
}

@end



@implementation GosubNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassCheckSemantic)
    {
        if (!runnable.labels[self.label])
        {
            NSException *exception = [ProgramException exceptionWithName:@"UndefinedLabel"
                                                                  reason:[NSString stringWithFormat:@"Undefined label %@", self.label]
                                                                   token:self.token];
            @throw exception;
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner gotoLabel:self.label isGosub:YES atToken:self.token];
    return nil;
}

@end



@implementation ReturnNode

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner returnFromGosubAtToken:self.token];
    return nil;
}

@end



@implementation PrintNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.expression prepareWithRunnable:runnable pass:pass canBeString:YES];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    id value = [self.expression evaluateWithRunner:runner];
    if (runner.delegate)
    {
        NSString *text = [NSString stringWithFormat:@"%@", value];
        int fontHeight = 6;
        int screenSize = runner.renderer.size;
        int maxLines = screenSize / fontHeight - 1;
        [runner.renderer drawText:text x:0 y:runner.printLine * fontHeight];
        runner.printLine++;
        if (runner.printLine > maxLines)
        {
            [runner.renderer scrollFromX:0 Y:0 toX:screenSize Y:screenSize deltaX:0 Y:-fontHeight];
            runner.printLine = maxLines;
        }
        [runner.delegate updateRendererView];
        [NSThread sleepForTimeInterval:0.1];
    }
    [runner next];
    return nil;
}

@end



@interface ForNextNode ()
@property float limit;
@property float increment;
@end

@implementation ForNextNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.variable prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.startExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.endExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.stepExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    
    if (self.matchingVariable)
    {
        [self.matchingVariable prepareWithRunnable:runnable pass:pass canBeString:NO];
        if (pass == PrePassCheckSemantic && ![self.variable.identifier isEqualToString:self.matchingVariable.identifier])
        {
            NSException *exception = [ProgramException exceptionWithName:@"UnmatchingNext"
                                                                  reason:@"NEXT not matching with FOR"
                                                                   token:self.token];
            @throw exception;
        }
    }
    
    [runnable prepareNodes:self.commands pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *startValue = [self.startExpression evaluateWithRunner:runner];
    NSNumber *endValue = [self.endExpression evaluateWithRunner:runner];
    NSNumber *stepValue = [self.stepExpression evaluateWithRunner:runner];
    
    [runner setValue:startValue forVariable:self.variable];
    self.limit = endValue.floatValue;
    self.increment = stepValue.floatValue;
    
    if ((self.increment > 0 && startValue.floatValue <= self.limit) || (self.increment < 0 && startValue.floatValue >= self.limit))
    {
        [runner addSequenceWithNodes:self.commands isLoop:YES parent:self];
    }
    else
    {
        [runner next];
    }
    return nil;
}

- (void)endOfLoopWithRunner:(Runner *)runner
{
    NSNumber *oldValue = [runner valueOfVariable:self.variable];
    NSNumber *value = @(oldValue.floatValue + self.increment);
    [runner setValue:value forVariable:self.variable];
    if ((self.increment > 0 && value.floatValue > self.limit) || (self.increment < 0 && value.floatValue < self.limit))
    {
        [runner exitLoopAtToken:self.token];
    }
    else
    {
        [runner resetSequence];
    }
}

@end



@implementation LetNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.variable prepareWithRunnable:runnable pass:pass];
    [self.expression prepareWithRunnable:runnable pass:pass];

    if (pass == PrePassCheckSemantic)
    {
        if (self.variable.isString != self.expression.returnsString)
        {
            @throw [ProgramException typeMismatchExceptionWithNode:self];
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    id value = [self.expression evaluateWithRunner:runner];
    [runner setValue:value forVariable:self.variable];
    [runner next];
    return nil;
}

@end



@implementation DimNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    for (VariableNode *variableNode in self.variableNodes)
    {
        [variableNode prepareWithRunnable:runnable pass:pass];
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    for (VariableNode *variableNode in self.variableNodes)
    {
        [runner dimVariable:variableNode];
    }
    [runner next];
    return nil;
}

@end



@implementation RepeatUntilNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.condition prepareWithRunnable:runnable pass:pass canBeString:NO];
    [runnable prepareNodes:self.commands pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner addSequenceWithNodes:self.commands isLoop:YES parent:self];
    return nil;
}

- (void)endOfLoopWithRunner:(Runner *)runner
{
    NSNumber *value = [self.condition evaluateWithRunner:runner];
    if (value.intValue == 0)
    {
        [runner resetSequence];
    }
    else
    {
        [runner exitLoopAtToken:self.token];
    }
}

@end



@implementation WhileWendNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.condition prepareWithRunnable:runnable pass:pass canBeString:NO];
    [runnable prepareNodes:self.commands pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *value = [self.condition evaluateWithRunner:runner];
    if (value.intValue == 0)
    {
        [runner next];
    }
    else
    {
        [runner addSequenceWithNodes:self.commands isLoop:YES parent:self];
    }
    return nil;
}

- (void)endOfLoopWithRunner:(Runner *)runner
{
    NSNumber *value = [self.condition evaluateWithRunner:runner];
    if (value.intValue == 0)
    {
        [runner exitLoopAtToken:self.token];
    }
    else
    {
        [runner resetSequence];
    }
}

@end



@implementation DoLoopNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [runnable prepareNodes:self.commands pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner addSequenceWithNodes:self.commands isLoop:YES parent:self];
    return nil;
}

- (void)endOfLoopWithRunner:(Runner *)runner
{
    [runner resetSequence];
}

@end



@implementation ExitNode

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner exitLoopAtToken:self.token];
    return nil;
}

@end



@implementation WaitNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.time prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner.delegate updateRendererView];
    
    NSNumber *value = [self.time evaluateWithRunner:runner];
    if (value.floatValue < 0.0)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:value.floatValue];
    }
    NSTimeInterval timeInterval = MIN(60.0, MAX(value.floatValue, 0.04));
    if (self.gamepad)
    {
        NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        int oldFlags = [runner.delegate currentGamepadFlags];
        while (CFAbsoluteTimeGetCurrent() - startTime < timeInterval)
        {
            int flags = [runner.delegate currentGamepadFlags];
            if (flags > oldFlags)
            {
                break;
            }
            oldFlags = flags;
            [NSThread sleepForTimeInterval:0.04];
        }
    }
    else
    {
        [NSThread sleepForTimeInterval:timeInterval];
    }
    [runner next];
    return nil;
}

@end



@implementation EndNode

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner end];
    return nil;
}

@end


@implementation GamepadNode

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *players = [self.playersExpression evaluateNumberWithRunner:runner min:0 max:1];
    [runner.delegate setGamepadModeWithPlayers:players.intValue];
    [runner next];
    return nil;
}

@end


@implementation ColorNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.color prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *value = [self.color evaluateNumberWithRunner:runner min:0 max:15];
    runner.renderer.colorIndex = value.intValue;
    [runner next];
    return nil;
}

@end



@implementation ClsNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.color prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *color = [self.color evaluateNumberWithRunner:runner min:0 max:15];
    [runner.renderer clearWithColorIndex:color.intValue];
    runner.printLine = 0;
    [runner next];
    return nil;
}

@end



@implementation PlotNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.yExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *x = [self.xExpression evaluateWithRunner:runner];
    NSNumber *y = [self.yExpression evaluateWithRunner:runner];
    [runner.renderer plotX:x.intValue Y:y.intValue];
    [runner next];
    return nil;
}

@end



@implementation LineNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.fromXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.fromYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *fromX = [self.fromXExpression evaluateWithRunner:runner];
    NSNumber *fromY = [self.fromYExpression evaluateWithRunner:runner];
    NSNumber *toX = [self.toXExpression evaluateWithRunner:runner];
    NSNumber *toY = [self.toYExpression evaluateWithRunner:runner];
    [runner.renderer drawFromX:fromX.intValue Y:fromY.intValue toX:toX.intValue Y:toY.intValue];
    [runner next];
    return nil;
}

@end



@implementation BoxNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.fromXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.fromYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *fromX = [self.fromXExpression evaluateWithRunner:runner];
    NSNumber *fromY = [self.fromYExpression evaluateWithRunner:runner];
    NSNumber *toX = [self.toXExpression evaluateWithRunner:runner];
    NSNumber *toY = [self.toYExpression evaluateWithRunner:runner];
    if (self.fill)
    {
        [runner.renderer fillBoxFromX:fromX.intValue Y:fromY.intValue toX:toX.intValue Y:toY.intValue];
    }
    else
    {
        [runner.renderer drawBoxFromX:fromX.intValue Y:fromY.intValue toX:toX.intValue Y:toY.intValue];
    }
    [runner next];
    return nil;
}

@end



@implementation ScrollNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.fromXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.fromYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.deltaXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.deltaYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *fromX = [self.fromXExpression evaluateWithRunner:runner];
    NSNumber *fromY = [self.fromYExpression evaluateWithRunner:runner];
    NSNumber *toX = [self.toXExpression evaluateWithRunner:runner];
    NSNumber *toY = [self.toYExpression evaluateWithRunner:runner];
    NSNumber *deltaX = [self.deltaXExpression evaluateWithRunner:runner];
    NSNumber *deltaY = [self.deltaYExpression evaluateWithRunner:runner];
    [runner.renderer scrollFromX:fromX.intValue Y:fromY.intValue toX:toX.intValue Y:toY.intValue deltaX:deltaX.intValue Y:deltaY.intValue];
    [runner next];
    return nil;
}

@end



@implementation TextNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.valueExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.yExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.alignExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    id value = [self.valueExpression evaluateWithRunner:runner];
    NSNumber *x = [self.xExpression evaluateWithRunner:runner];
    NSNumber *y = [self.yExpression evaluateWithRunner:runner];
    NSNumber *align = [self.alignExpression evaluateWithRunner:runner];
    int alignInt = align.intValue;
    float xPos = x.floatValue;
    NSString *text = [value description];
    if (alignInt > 0)
    {
        float width = [runner.renderer widthForText:text] - 2;
        if (alignInt == 1)
        {
            xPos -= width / 2;
        }
        else if (alignInt == 2)
        {
            xPos -= width;
        }
    }
    [runner.renderer drawText:text x:roundf(xPos) y:roundf(y.floatValue)];
    [runner next];
    return nil;
}

@end



@implementation DefSpriteNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.imageExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.dataVariable prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *image = [self.imageExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSpriteDefs - 1];
    ArrayVariable *arrayVariable = [runner arrayOfVariable:self.dataVariable];
    
    if (arrayVariable.sizes.count != 1 || ((NSNumber *)arrayVariable.sizes[0]).intValue != RendererSpriteSize * 2)
    {
        NSException *exception = [ProgramException exceptionWithName:@"IncorrectArraySize" reason:@"Incorrect array size" token:self.token];
        @throw exception;
    }
    
    SpriteDef *def = [runner.renderer spriteDefAtIndex:image.intValue];
    for (int i = 0; i < RendererSpriteSize; i++)
    {
        int val1 = ((NSNumber *)arrayVariable.values[i << 1]).intValue & 0xFF;
        int val2 = ((NSNumber *)arrayVariable.values[(i << 1) + 1]).intValue & 0xFF;
        def->data[i] = (val1 << 8) | val2;
    }
    
    [runner next];
    return nil;
}

@end



@implementation SpritePaletteNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.color1Expression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.color2Expression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.color3Expression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    NSNumber *color1 = [self.color1Expression evaluateNumberWithRunner:runner min:0 max:15];
    NSNumber *color2 = [self.color2Expression evaluateNumberWithRunner:runner min:0 max:15];
    NSNumber *color3 = [self.color3Expression evaluateNumberWithRunner:runner min:0 max:15];
    
    Sprite *sprite = [runner.renderer spriteAtIndex:n.intValue];
    sprite->colors[0] = color1.intValue;
    sprite->colors[1] = color2.intValue;
    sprite->colors[2] = color3.intValue;
    
    [runner next];
    return nil;
}

@end



@implementation SpriteNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.yExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.imageExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    NSNumber *x = [self.xExpression evaluateWithRunner:runner];
    NSNumber *y = [self.yExpression evaluateWithRunner:runner];
    NSNumber *image = [self.imageExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSpriteDefs - 1];
    
    Sprite *sprite = [runner.renderer spriteAtIndex:n.intValue];
    sprite->visible = YES;
    sprite->x = x.intValue;
    sprite->y = y.intValue;
    sprite->image = image.intValue;
    
    [runner next];
    return nil;
}

@end



@implementation SpriteOffNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    
    Sprite *sprite = [runner.renderer spriteAtIndex:n.intValue];
    sprite->visible = NO;
    
    [runner next];
    return nil;
}

@end



@implementation DataNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassInit)
    {
        [runnable.dataNodes addObject:self];
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner next];
    return nil;
}

@end



@implementation ReadNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    for (VariableNode *variable in self.variables)
    {
        [variable prepareWithRunnable:runnable pass:pass];
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    for (VariableNode *variable in self.variables)
    {
        Node *constant = [runner readDataAtToken:variable.token];
        
        if (constant.returnsString != variable.isString)
        {
            @throw [ProgramException typeMismatchExceptionWithNode:variable];
        }
        
        id value = [constant evaluateWithRunner:runner];
        [runner setValue:value forVariable:variable];
    }
    [runner next];
    return nil;
}

@end



@implementation RestoreNode : Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassCheckSemantic)
    {
        if (self.label && !runnable.labels[self.label] && ![self.label isEqualToString:TRANSFER])
        {
            NSException *exception = [ProgramException exceptionWithName:@"UndefinedLabel"
                                                                  reason:[NSString stringWithFormat:@"Undefined label %@", self.label]
                                                                   token:self.token];
            @throw exception;
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    if ([self.label isEqualToString:TRANSFER])
    {
        [runner restoreDataTransfer];
    }
    else
    {
        [runner restoreDataLabel:self.label atToken:self.token];
    }
    [runner next];
    return nil;
}

@end



@implementation WriteNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    for (Node *valueNode in self.valueExpressions)
    {
        [valueNode prepareWithRunnable:runnable pass:pass];
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    if (self.clear)
    {
        [runner.transferStrings removeAllObjects];
    }
    else
    {
        NSMutableArray *strings = [NSMutableArray array];
        for (Node *valueNode in self.valueExpressions)
        {
            NSString *string;
            id value = [valueNode evaluateWithRunner:runner];
            if ([value isKindOfClass:[NSString class]])
            {
                string = [NSString stringWithFormat:@"\"%@\"", value];
            }
            else
            {
                string = [value stringValue];
            }
            [strings addObject:string];
        }
        NSString *dataString = [strings componentsJoinedByString:@","];
        [runner.transferStrings addObject:[NSString stringWithFormat:@"DATA %@", dataString]];
    }
    [runner next];
    return nil;
}

@end



@implementation DirectionPadNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.portExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *port = [self.portExpression evaluateNumberWithRunner:runner min:0 max:0];
    BOOL result = NO;
    switch (self.type)
    {
        case TTypeSymUp:
            result = [runner.delegate isButtonDown:ButtonTypeUp];
            break;
        case TTypeSymDown:
            result = [runner.delegate isButtonDown:ButtonTypeDown];
            break;
        case TTypeSymLeft:
            result = [runner.delegate isButtonDown:ButtonTypeLeft];
            break;
        case TTypeSymRight:
            result = [runner.delegate isButtonDown:ButtonTypeRight];
            break;
        case TTypeSymButton:
            result = [runner.delegate isButtonDown:ButtonTypeA];
            break;
        default:
            break;
    }
    return @(result ? -1 : 0);
}

@end


@implementation ButtonNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.portExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.buttonExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *port = [self.portExpression evaluateNumberWithRunner:runner min:0 max:0];
    NSNumber *button = [self.buttonExpression evaluateWithRunner:runner];
    BOOL result = NO;
    switch (button.intValue)
    {
        case 0:
            result = [runner.delegate isButtonDown:ButtonTypeA] || [runner.delegate isButtonDown:ButtonTypeB];
            break;
            
        case 1:
            result = [runner.delegate isButtonDown:ButtonTypeA];
            break;
            
        case 2:
            result = [runner.delegate isButtonDown:ButtonTypeB];
            break;
            
        default:
            @throw [ProgramException invalidParameterExceptionWithNode:self value:button.intValue];
            break;
    }
    return @(result ? -1 : 0);
}

@end


@implementation PointNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.yExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *x = [self.xExpression evaluateWithRunner:runner];
    NSNumber *y = [self.yExpression evaluateWithRunner:runner];
    return @([runner.renderer colorAtX:x.intValue Y:y.intValue]);
}

@end



@implementation TextWidthNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.valueExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    id value = [self.valueExpression evaluateWithRunner:runner];
    NSString *string = ([value isKindOfClass:[NSString class]]) ? (NSString *)value : [NSString stringWithFormat:@"%@", value];
    int width = [runner.renderer widthForText:string];
    return @(width);
}

@end

@implementation Maths0Node

- (id)evaluateWithRunner:(Runner *)runner
{
    float result = 0;
    switch (self.type)
    {
        case TTypeSymRnd:
            result = arc4random() / ((float)UINT32_MAX + 1.0); rand();
            break;
        default:
            break;
    }
    return @(result);
}

@end



@implementation Maths1Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *x = [self.xExpression evaluateWithRunner:runner];
    float value = x.floatValue;
    float result = 0;
    switch (self.type)
    {
        case TTypeSymAbs:
            result = fabsf(value);
            break;
        case TTypeSymAtn:
            result = atanf(value);
            break;
        case TTypeSymCos:
            result = cosf(value);
            break;
        case TTypeSymExp:
            result = expf(value);
            break;
        case TTypeSymInt:
            result = floorf(value);
            break;
        case TTypeSymLog:
            if (value <= 0)
            {
                @throw [ProgramException invalidParameterExceptionWithNode:self value:value];
            }
            result = logf(value);
            break;
        case TTypeSymSgn:
            result = (value > 0) ? 1 : (value < 0) ? -1 : 0;
            break;
        case TTypeSymSin:
            result = sinf(value);
            break;
        case TTypeSymSqr:
            if (value < 0)
            {
                @throw [ProgramException invalidParameterExceptionWithNode:self value:value];
            }
            result = sqrtf(value);
            break;
        case TTypeSymTan:
            result = tanf(value);
            break;
        default:
            break;
    }
    return @(result);
}

@end



@implementation LeftSNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.stringExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
    [self.numberExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSString *string = [self.stringExpression evaluateWithRunner:runner];
    NSNumber *number = [self.numberExpression evaluateWithRunner:runner];
    if (number.intValue < 0)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:number.intValue];
    }
    if (number.intValue >= string.length)
    {
        return string;
    }
    return [string substringToIndex:number.intValue];
}

- (BOOL)returnsString
{
    return YES;
}

@end



@implementation RightSNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.stringExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
    [self.numberExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSString *string = [self.stringExpression evaluateWithRunner:runner];
    NSNumber *number = [self.numberExpression evaluateWithRunner:runner];
    NSUInteger len = string.length;
    if (number.intValue < 0)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:number.intValue];
    }
    if (number.intValue >= len)
    {
        return string;
    }
    return [string substringFromIndex:len - number.intValue];
}

- (BOOL)returnsString
{
    return YES;
}

@end



@implementation MidNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.stringExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
    [self.positionExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.numberExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSString *string = [self.stringExpression evaluateWithRunner:runner];
    NSNumber *position = [self.positionExpression evaluateWithRunner:runner];
    NSNumber *number = [self.numberExpression evaluateWithRunner:runner];
    NSUInteger len = string.length;
    if (position.intValue < 1)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:position.intValue];
    }
    if (number.intValue < 1)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:number.intValue];
    }
    if (position.intValue - 1 + number.intValue > len)
    {
        return [string substringFromIndex:position.intValue - 1];
    }
    return [string substringWithRange:NSMakeRange(position.intValue - 1, number.intValue)];
}

- (BOOL)returnsString
{
    return YES;
}

@end



@implementation InstrNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.stringExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
    [self.searchExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
    [self.positionExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSString *string = [self.stringExpression evaluateWithRunner:runner];
    NSString *search = [self.searchExpression evaluateWithRunner:runner];
    NSNumber *position = [self.positionExpression evaluateWithRunner:runner];
    NSUInteger len = string.length;
    
    if (position.intValue < 1)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:position.intValue];
    }
    if (position.intValue > len)
    {
        return @(0);
    }
    
    NSRange range = [string rangeOfString:search options:0 range:NSMakeRange(position.intValue - 1, len - position.intValue + 1)];
    if (range.location == NSNotFound)
    {
        return @(0);
    }
    return @(range.location + 1);
}

@end



@implementation ChrNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.asciiExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *ascii = [self.asciiExpression evaluateNumberWithRunner:runner min:0 max:127];
    const unichar character = (const unichar)ascii.intValue;
    return [NSString stringWithCharacters:&character length:1];
}

- (BOOL)returnsString
{
    return YES;
}

@end



@implementation AscNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.stringExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSString *string = [self.stringExpression evaluateWithRunner:runner];
    if (string.length < 1)
    {
        @throw [ProgramException invalidParameterExceptionWithNode:self value:0];
    }
    unichar character = [string characterAtIndex:0];
    return @((int)character);
}

@end



@implementation LenNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.stringExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSString *string = [self.stringExpression evaluateWithRunner:runner];
    return @(string.length);
}

@end



@implementation ValNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.stringExpression prepareWithRunnable:runnable pass:pass canBeString:YES];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSString *string = [self.stringExpression evaluateWithRunner:runner];
    return @(string.floatValue);
}

@end



@implementation StrNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.numberExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *number = [self.numberExpression evaluateWithRunner:runner];
    return number.stringValue;
}

- (BOOL)returnsString
{
    return YES;
}

@end



@implementation HexNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.numberExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *number = [self.numberExpression evaluateWithRunner:runner];
    return [NSString stringWithFormat:@"%X", number.intValue];
}

- (BOOL)returnsString
{
    return YES;
}

@end



@implementation Operator2Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.leftExpression prepareWithRunnable:runnable pass:pass];
    [self.rightExpression prepareWithRunnable:runnable pass:pass];

    if (pass == PrePassCheckSemantic)
    {
        BOOL leftReturnsString = self.leftExpression.returnsString;
        BOOL rightReturnsString = self.rightExpression.returnsString;
        switch (self.type)
        {
            case TTypeSymOpPlus:
                break;
                
            case TTypeSymOpEq:
            case TTypeSymOpUneq:
                if (leftReturnsString != rightReturnsString)
                {
                    @throw [ProgramException typeMismatchExceptionWithNode:self];
                }
                break;

            default:
                if (leftReturnsString || rightReturnsString)
                {
                    @throw [ProgramException typeMismatchExceptionWithNode:self];
                }
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    id leftValue = [self.leftExpression evaluateWithRunner:runner];
    id rightValue = [self.rightExpression evaluateWithRunner:runner];
    BOOL leftIsString = [leftValue isKindOfClass:[NSString class]];
    BOOL rightIsString = [rightValue isKindOfClass:[NSString class]];
    
    switch (self.type)
    {
        case TTypeSymOpOr: {
            int leftInt = ((NSNumber *)leftValue).intValue;
            int rightInt = ((NSNumber *)rightValue).intValue;
            return @(leftInt | rightInt);
        }
        case TTypeSymOpXor: {
            int leftInt = ((NSNumber *)leftValue).intValue;
            int rightInt = ((NSNumber *)rightValue).intValue;
            return @(leftInt ^ rightInt);
        }
        case TTypeSymOpAnd: {
            int leftInt = ((NSNumber *)leftValue).intValue;
            int rightInt = ((NSNumber *)rightValue).intValue;
            return @(leftInt & rightInt);
        }
        case TTypeSymOpPlus: {
            if (leftIsString || rightIsString)
            {
                return [NSString stringWithFormat:@"%@%@", leftValue, rightValue];
            }
            else
            {
                float result = ((NSNumber *)leftValue).floatValue + ((NSNumber *)rightValue).floatValue;
                return @(result);
            }
        }
        case TTypeSymOpMinus: {
            float result = ((NSNumber *)leftValue).floatValue - ((NSNumber *)rightValue).floatValue;
            return @(result);
        }
        case TTypeSymOpMul: {
            float result = ((NSNumber *)leftValue).floatValue * ((NSNumber *)rightValue).floatValue;
            return @(result);
        }
        case TTypeSymOpDiv: {
            float result = ((NSNumber *)leftValue).floatValue / ((NSNumber *)rightValue).floatValue;
            return @(result);
        }
        case TTypeSymOpMod: {
            int result = ((NSNumber *)leftValue).intValue % ((NSNumber *)rightValue).intValue;
            return @(result);
        }
        case TTypeSymOpPow: {
            int result = powf(((NSNumber *)leftValue).floatValue, ((NSNumber *)rightValue).floatValue);
            return @(result);
        }
        case TTypeSymOpEq:
        case TTypeSymOpUneq: {
            BOOL result;
            if (leftIsString && rightIsString)
            {
                result = [leftValue isEqualToString:rightValue];
            }
            else
            {
                result = ((NSNumber *)leftValue).floatValue == ((NSNumber *)rightValue).floatValue;
            }
            if (self.type == TTypeSymOpUneq)
            {
                result = !result;
            }
            return @(result ? -1 : 0);
        }
        case TTypeSymOpGr: {
            BOOL result = ((NSNumber *)leftValue).floatValue > ((NSNumber *)rightValue).floatValue;
            return @(result ? -1 : 0);
        }
        case TTypeSymOpLe: {
            BOOL result = ((NSNumber *)leftValue).floatValue < ((NSNumber *)rightValue).floatValue;
            return @(result ? -1 : 0);
        }
        case TTypeSymOpGrEq: {
            BOOL result = ((NSNumber *)leftValue).floatValue >= ((NSNumber *)rightValue).floatValue;
            return @(result ? -1 : 0);
        }
        case TTypeSymOpLeEq: {
            BOOL result = ((NSNumber *)leftValue).floatValue <= ((NSNumber *)rightValue).floatValue;
            return @(result ? -1 : 0);
        }
        default: {
            // invalid
        }
    }
    return @(0);
}

- (BOOL)returnsString
{
    if (self.type == TTypeSymOpPlus)
    {
        return self.leftExpression.returnsString || self.rightExpression.returnsString;
    }
    return NO;
}

@end



@implementation Operator1Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.expression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *value = [self.expression evaluateWithRunner:runner];
    switch (self.type)
    {
        case TTypeSymOpPlus:
            return value;
        case TTypeSymOpMinus:
            return @(-value.floatValue);
        case TTypeSymOpNot:
            return @(~value.intValue);
        default: {
            // invalid
        }
    }
    return value;
}

@end
