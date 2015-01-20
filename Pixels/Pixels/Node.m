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

- (id)evaluateWithRunner:(Runner *)runner
{
    return @(self.value);
}

@end



@implementation StringNode

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

- (id)evaluateWithRunner:(Runner *)runner
{
    return [runner valueOfVariable:self];
}

- (BOOL)returnsString
{
    return self.isString;
}

@end



@implementation LabelNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassInit)
    {
        runnable.labels[self.identifier] = self;
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
    BOOL success = [runner gotoLabel:self.label isGosub:NO];
    if (!success)
    {
        NSException *exception = [ProgramException exceptionWithName:@"UnaccessibleLabel"
                                                              reason:[NSString stringWithFormat:@"Unaccessible label %@", self.label]
                                                               token:self.token];
        @throw exception;
    }
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
    BOOL success = [runner gotoLabel:self.label isGosub:YES];
    if (!success)
    {
        NSException *exception = [ProgramException exceptionWithName:@"UnaccessibleLabel"
                                                              reason:[NSString stringWithFormat:@"Unaccessible label %@", self.label]
                                                               token:self.token];
        @throw exception;
    }
    return nil;
}

@end



@implementation ReturnNode

- (id)evaluateWithRunner:(Runner *)runner
{
    BOOL success = [runner returnFromGosub];
    if (!success)
    {
        NSException *exception = [ProgramException exceptionWithName:@"ReturnWithoutGosub"
                                                              reason:[NSString stringWithFormat:@"RETURN without GOSUB"]
                                                               token:self.token];
        @throw exception;
    }
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
        [runner.delegate runnerLog:[NSString stringWithFormat:@"%@", value]];
    }
    [runner next];
    return nil;
}

@end



@implementation ForNextNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.variable prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.startExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.endExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    
    [runnable prepareNodes:self.commands pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *startValue = [self.startExpression evaluateWithRunner:runner];
    NSNumber *endValue = [self.endExpression evaluateWithRunner:runner];
    
    [runner setValue:startValue forVariable:self.variable];
    if (startValue.floatValue <= endValue.floatValue)
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
    NSNumber *value = @(oldValue.floatValue + 1);
    NSNumber *endValue = [self.endExpression evaluateWithRunner:runner];
    [runner setValue:value forVariable:self.variable];
    if (value.floatValue > endValue.floatValue)
    {
        [runner exitLoop];
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
        [runner exitLoop];
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
        [runner exitLoop];
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
    [runner exitLoop];
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
    NSTimeInterval timeInterval = MAX(value.floatValue, 0.04);
    [NSThread sleepForTimeInterval:timeInterval];
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
    NSNumber *players = [self.playersExpression evaluateWithRunner:runner];
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
    NSNumber *value = [self.color evaluateWithRunner:runner];
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
    NSNumber *color = [self.color evaluateWithRunner:runner];
    [runner.renderer clearWithColorIndex:color.intValue];
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



@implementation DirectionPadNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.portExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
//    NSNumber *port = [self.portExpression evaluateWithRunner:runner];
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
    //    NSNumber *port = [self.portExpression evaluateWithRunner:runner];
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



@implementation Maths0Node

- (id)evaluateWithRunner:(Runner *)runner
{
    float result = 0;
    switch (self.type)
    {
        case TTypeSymRnd:
            result = arc4random() / ((float)UINT32_MAX + 1.0);
            break;
        default:
            break;
    }
    return @(result);
}

@end



@implementation Maths1Node

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *x = [self.xExpression evaluateWithRunner:runner];
    return x; //TODO
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
            if (value.intValue == 0)
            {
                return @(-1);
            }
            return @(0);
        default: {
            // invalid
        }
    }
    return value;
}

@end
