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

@implementation Node

- (id)evaluateWithRunner:(Runner *)runner
{
    return nil;
}

- (void)endOfLoopWithRunner:(Runner *)runner
{
}

@end

@implementation IfNode

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *value = [self.condition evaluateWithRunner:runner];
    if (value.intValue == 0)
    {
        [runner next];
    }
    else
    {
        [runner addSequenceWithNodes:self.commands isLoop:NO parent:self];
    }
    return nil;
}

@end

@implementation GotoNode
@end

@implementation GosubNode
@end

@implementation ReturnNode
@end

@implementation PrintNode

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

- (id)evaluateWithRunner:(Runner *)runner
{
    id value = [self.expression evaluateWithRunner:runner];
    [runner setValue:value forVariable:self.identifier];
    [runner next];
    return nil;
}

@end

@implementation RepeatUntilNode

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

- (id)evaluateWithRunner:(Runner *)runner
{
    [runner.delegate updateRendererView];
    
    NSNumber *value = [self.time evaluateWithRunner:runner];
    NSTimeInterval timeInterval = value.floatValue;
    [NSThread sleepForTimeInterval:timeInterval];
    [runner next];
    return nil;
}

@end

@implementation ColorNode

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *value = [self.color evaluateWithRunner:runner];
    runner.renderer.colorIndex = value.intValue;
    [runner next];
    return nil;
}

@end

@implementation ClearNode

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *color = [self.color evaluateWithRunner:runner];
    [runner.renderer clearWithColorIndex:color.intValue];
    [runner next];
    return nil;
}

@end

@implementation PlotNode

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

- (id)evaluateWithRunner:(Runner *)runner
{
    NSNumber *fromX = [self.fromXExpression evaluateWithRunner:runner];
    NSNumber *fromY = [self.fromYExpression evaluateWithRunner:runner];
    NSNumber *toX = [self.toXExpression evaluateWithRunner:runner];
    NSNumber *toY = [self.toYExpression evaluateWithRunner:runner];
    [runner.renderer drawBoxFromX:fromX.intValue Y:fromY.intValue toX:toX.intValue Y:toY.intValue];
    [runner next];
    return nil;
}

@end

@implementation TextNode

- (id)evaluateWithRunner:(Runner *)runner
{
    id value = [self.valueExpression evaluateWithRunner:runner];
    NSNumber *x = [self.xExpression evaluateWithRunner:runner];
    NSNumber *y = [self.yExpression evaluateWithRunner:runner];
    NSNumber *align = [self.alignExpression evaluateWithRunner:runner];
    int alignInt = align.intValue;
    int xPos = x.intValue;
    NSString *text = [value description];
    if (alignInt > 0)
    {
        int width = [runner.renderer widthForText:text] - 2;
        if (alignInt == 1)
        {
            xPos -= width / 2;
        }
        else if (alignInt == 2)
        {
            xPos -= width;
        }
    }
    [runner.renderer drawText:text x:xPos y:y.intValue];
    [runner next];
    return nil;
}

@end

@implementation JoystickNode

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

@implementation PointNode

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
            result = arc4random() / (float)UINT32_MAX;
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

@end

@implementation Operator1Node

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

@end

@implementation VariableNode

- (id)evaluateWithRunner:(Runner *)runner
{
    return [runner valueOfVariable:self.identifier];
}

@end

@implementation LabelNode

- (id)evaluateWithRunner:(Runner *)runner
{
    return self.identifier;
}

@end
