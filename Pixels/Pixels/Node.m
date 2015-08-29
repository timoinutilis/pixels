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
#import "AudioPlayer.h"
#import "NSError+LowResCoder.h"
#import "VariableManager.h"
#import "NumberPool.h"

NSString *const TRANSFER = @"TRANSFER";

@implementation Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
}

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass canBeString:(BOOL)canBeString
{
    if (pass == PrePassCheckSemantic && !canBeString && self.returnsString)
    {
        runnable.error = [NSError typeMismatchErrorWithNode:self];
        return;
    }
    [self prepareWithRunnable:runnable pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    return nil;
}

- (Number *)evaluateNumberWithRunner:(Runner *)runner min:(int)min max:(int)max
{
    Number *number = [self evaluateWithRunner:runner];
    if (number && (number.intValue < min || number.intValue > max))
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:number.intValue];
        return nil;
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
    return [runner.numberPool numberWithValue:self.value];
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
    return [runner.variables valueOfVariable:self];
}

- (BOOL)returnsString
{
    return self.isString;
}

- (NSArray *)indexesWithRunner:(Runner *)runner isDim:(BOOL)isDim
{
    NSMutableArray *indexes = [NSMutableArray array];
    for (Node *expressionNode in self.indexExpressions)
    {
        Number *indexNumber = [expressionNode evaluateWithRunner:runner];
        if (isDim)
        {
            indexNumber = [Number numberWithValue:(indexNumber.intValue + 1)];
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
    Number *value = [self.condition evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
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
            runnable.error = [NSError undefinedLabelErrorWithNode:self label:self.label];
            return;
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
            runnable.error = [NSError undefinedLabelErrorWithNode:self label:self.label];
            return;
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

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassCheckSemantic)
    {
        if (self.label && !runnable.labels[self.label])
        {
            runnable.error = [NSError undefinedLabelErrorWithNode:self label:self.label];
            return;
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    if (self.label)
    {
        [runner returnFromGosubToLabel:self.label atToken:self.token];
    }
    else
    {
        [runner returnFromGosubAtToken:self.token];
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
    if (runner.error)
    {
        return nil;
    }
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
        [runner wait:0.1 stopBlock:nil];
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
            runnable.error = [NSError programErrorWithCode:LRCErrorCodeSemantic reason:@"NEXT not matching with FOR" token:self.token];
            return;
        }
    }
    
    [runnable prepareNodes:self.commands pass:pass];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *startValue = [self.startExpression evaluateWithRunner:runner];
    Number *endValue = [self.endExpression evaluateWithRunner:runner];
    Number *stepValue = [self.stepExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    [runner.variables setValue:startValue forVariable:self.variable];
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
    Number *oldValue = [runner.variables valueOfVariable:self.variable];
    if (runner.error)
    {
        return;
    }
    Number *value = [runner.numberPool numberWithValue:(oldValue.floatValue + self.increment)];
    [runner.variables setValue:value forVariable:self.variable];
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
            runnable.error = [NSError typeMismatchErrorWithNode:self];
            return;
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    id value = [self.expression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    [runner.variables setValue:value forVariable:self.variable];
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
        [runner.variables dimVariable:variableNode];
        if (self.persist)
        {
            [runner.variables persistVariable:variableNode asArray:YES];
        }
    }
    [runner next];
    return nil;
}

@end



@implementation PersistNode

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
        [runner.variables persistVariable:variableNode asArray:NO];
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
    Number *value = [self.condition evaluateWithRunner:runner];
    if (runner.error)
    {
        return;
    }
    
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
    Number *value = [self.condition evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
    Number *value = [self.condition evaluateWithRunner:runner];
    if (runner.error)
    {
        return;
    }
    
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
    
    Number *value = [self.time evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    if (value.floatValue < 0.0)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:value.floatValue];
        return nil;
    }
    NSTimeInterval timeInterval = MAX(value.floatValue, 0.04);
    if (self.tap)
    {
        __block int oldFlags = [runner.delegate currentGamepadFlags];
        
        [runner wait:timeInterval stopBlock:^BOOL{
            int flags = [runner.delegate currentGamepadFlags];
            if (flags > oldFlags)
            {
                return YES;
            }
            oldFlags = flags;
            return NO;
        }];
        
    }
    else
    {
        [runner wait:timeInterval stopBlock:nil];
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

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.playersExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    if (pass == PrePassInit)
    {
        runnable.usesGamepad = YES;
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *players = [self.playersExpression evaluateNumberWithRunner:runner min:0 max:1];
    if (runner.error)
    {
        return nil;
    }
    
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
    Number *value = [self.color evaluateNumberWithRunner:runner min:0 max:15];
    if (runner.error)
    {
        return nil;
    }
    
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
    int c = 0;
    if (self.color)
    {
        Number *color = [self.color evaluateNumberWithRunner:runner min:0 max:15];
        c = color.intValue;
    }
    if (runner.error)
    {
        return nil;
    }
    
    [runner.renderer clearWithColorIndex:c];
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
    Number *x = [self.xExpression evaluateWithRunner:runner];
    Number *y = [self.yExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
    Number *fromX = [self.fromXExpression evaluateWithRunner:runner];
    Number *fromY = [self.fromYExpression evaluateWithRunner:runner];
    Number *toX = [self.toXExpression evaluateWithRunner:runner];
    Number *toY = [self.toYExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
    Number *fromX = [self.fromXExpression evaluateWithRunner:runner];
    Number *fromY = [self.fromYExpression evaluateWithRunner:runner];
    Number *toX = [self.toXExpression evaluateWithRunner:runner];
    Number *toY = [self.toYExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
    Number *fromX = [self.fromXExpression evaluateWithRunner:runner];
    Number *fromY = [self.fromYExpression evaluateWithRunner:runner];
    Number *toX = [self.toXExpression evaluateWithRunner:runner];
    Number *toY = [self.toYExpression evaluateWithRunner:runner];
    Number *deltaX = [self.deltaXExpression evaluateWithRunner:runner];
    Number *deltaY = [self.deltaYExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
    Number *x = [self.xExpression evaluateWithRunner:runner];
    Number *y = [self.yExpression evaluateWithRunner:runner];
    Number *align = [self.alignExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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



@implementation PaintNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.yExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *x = [self.xExpression evaluateWithRunner:runner];
    Number *y = [self.yExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    [runner.renderer floodFillX:x.intValue Y:y.intValue];
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
    Number *image = [self.imageExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSpriteDefs - 1];
    ArrayVariable *arrayVariable = [runner.variables arrayOfVariable:self.dataVariable];
    if (runner.error)
    {
        return nil;
    }
    
    if (arrayVariable.sizes.count != 1 || ((Number *)arrayVariable.sizes[0]).intValue != RendererSpriteSize * 2)
    {
        runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"Incorrect array size" token:self.token];
        return nil;
    }
    
    SpriteDef *def = [runner.renderer spriteDefAtIndex:image.intValue];
    for (int i = 0; i < RendererSpriteSize; i++)
    {
        int val1 = [arrayVariable intAtOffset:(i << 1)] & 0xFF;
        int val2 = [arrayVariable intAtOffset:(i << 1) + 1] & 0xFF;
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
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    if (runner.error)
    {
        return nil;
    }
    
    Sprite *sprite = [runner.renderer spriteAtIndex:n.intValue];
    if (self.color1Expression)
    {
        Number *color1 = [self.color1Expression evaluateNumberWithRunner:runner min:0 max:15];
        sprite->colors[0] = color1.intValue;
    }
    if (self.color2Expression)
    {
        Number *color2 = [self.color2Expression evaluateNumberWithRunner:runner min:0 max:15];
        sprite->colors[1] = color2.intValue;
    }
    if (self.color3Expression)
    {
        Number *color3 = [self.color3Expression evaluateNumberWithRunner:runner min:0 max:15];
        sprite->colors[2] = color3.intValue;
    }
    
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
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    if (runner.error)
    {
        return nil;
    }
    
    Sprite *sprite = [runner.renderer spriteAtIndex:n.intValue];
    sprite->visible = YES;
    if (self.xExpression)
    {
        Number *x = [self.xExpression evaluateWithRunner:runner];
        sprite->x = x.floatValue;
    }
    if (self.yExpression)
    {
        Number *y = [self.yExpression evaluateWithRunner:runner];
        sprite->y = y.floatValue;
    }
    if (self.imageExpression)
    {
        Number *image = [self.imageExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSpriteDefs - 1];
        sprite->image = image.intValue;
    }
    
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
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    if (runner.error)
    {
        return nil;
    }
    
    if (n)
    {
        Sprite *sprite = [runner.renderer spriteAtIndex:n.intValue];
        sprite->visible = NO;
    }
    else
    {
        for (int i = 0; i < RendererNumSprites; i++)
        {
            Sprite *sprite = [runner.renderer spriteAtIndex:i];
            sprite->visible = NO;
        }
    }
    
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
        if (runner.error)
        {
            return nil;
        }
        
        if (constant.returnsString != variable.isString)
        {
            runner.error = [NSError typeMismatchErrorWithNode:variable];
            return nil;
        }
        
        id value = [constant evaluateWithRunner:runner];
        if (runner.error)
        {
            return nil;
        }
        
        [runner.variables setValue:value forVariable:variable];
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
            runnable.error = [NSError undefinedLabelErrorWithNode:self label:self.label];
            return;
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
            if (runner.error)
            {
                return nil;
            }
            
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



@implementation OnXGotoNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    if (pass == PrePassCheckSemantic)
    {
        if (self.label && !runnable.labels[self.label])
        {
            runnable.error = [NSError undefinedLabelErrorWithNode:self label:self.label];
            return;
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    OnXGotoNode *node = (self.label ? self : nil);
    if (self.xType == TTypeSymEnd)
    {
        runner.currentOnEndGoto = node;
    }
    else if (self.xType == TTypeSymPause)
    {
        runner.currentOnPauseGoto = node;
    }
    [runner next];
    return nil;
}

@end



@implementation DefSoundNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.waveExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.pulseWidthExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.maxTimeExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:AudioNumSoundDefs - 1];
    Number *wave = [self.waveExpression evaluateNumberWithRunner:runner min:0 max:3];
    Number *pulseWidth = [self.pulseWidthExpression evaluateWithRunner:runner];
    Number *maxTime = [self.maxTimeExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    if (pulseWidth && (pulseWidth.floatValue < 0.0 || pulseWidth.floatValue > 1.0))
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:pulseWidth.floatValue];
        return nil;
    }
    if (maxTime && maxTime.floatValue < 0)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:maxTime.floatValue];
        return nil;
    }
    
    SoundDef *def = [runner.audioPlayer soundDefAtIndex:n.intValue];
    def->wave = wave.intValue;
    def->pulseWidth = pulseWidth ? pulseWidth.floatValue : 0.5;
    def->maxTime = maxTime.floatValue;

    // reset values from Def Sound Line
    def->bendTime = 1.0;
    def->pitchBend = 0;
    def->pulseBend = 0;
    
    [runner next];
    return nil;
}

@end



@implementation DefSoundLineNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.bendTimeExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.pitchBendExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.pulseBendExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:AudioNumSoundDefs - 1];
    Number *bendTime = [self.bendTimeExpression evaluateWithRunner:runner];
    Number *pitchBend = [self.pitchBendExpression evaluateWithRunner:runner];
    Number *pulseBend = [self.pulseBendExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    if (pulseBend && (pulseBend.floatValue < -1.0 || pulseBend.floatValue > 1.0))
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:pulseBend.floatValue];
        return nil;
    }
    
    SoundDef *def = [runner.audioPlayer soundDefAtIndex:n.intValue];
    def->bendTime = bendTime.floatValue;
    def->pitchBend = pitchBend.intValue;
    def->pulseBend = pulseBend.floatValue;
    
    [runner next];
    return nil;
}

@end



@implementation SoundNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.voiceExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.pitchExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.durationExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.defExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    
    if (pass == PrePassInit)
    {
        runnable.usesSound = YES;
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *voice = [self.voiceExpression evaluateNumberWithRunner:runner min:0 max:AudioNumVoices - 1];
    Number *pitch = [self.pitchExpression evaluateNumberWithRunner:runner min:0 max:96];
    Number *duration = [self.durationExpression evaluateNumberWithRunner:runner min:0 max:127];
    Number *soundDef = [self.defExpression evaluateNumberWithRunner:runner min:0 max:AudioNumSoundDefs - 1];
    if (runner.error)
    {
        return nil;
    }
    
    // audio system will start if not started before
    [runner.audioPlayer start];
    
    if (duration.intValue == 0)
    {
        // set voice immediately
        [runner.audioPlayer setVoice:voice.intValue pitch:pitch.intValue soundDef:(soundDef ? soundDef.intValue : -1)];
    }
    else
    {
        // add to queue
        SoundNote *note = [runner.audioPlayer nextNoteForVoice:voice.intValue];
        note->pitch = pitch.intValue;
        note->duration = duration.intValue;
        note->soundDef = soundDef ? soundDef.intValue : -1;
    }
    
    [runner next];
    return nil;
}

@end



@implementation SoundOffNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.voiceExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *voice = [self.voiceExpression evaluateNumberWithRunner:runner min:0 max:AudioNumVoices - 1];
    if (runner.error)
    {
        return nil;
    }
    
    if (voice)
    {
        [runner.audioPlayer resetVoice:voice.intValue];
    }
    else
    {
        for (int i = 0; i < AudioNumVoices; i++)
        {
            [runner.audioPlayer resetVoice:i];
        }
    }
    
    [runner next];
    return nil;
}

@end



@implementation SoundEndNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.voiceExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    BOOL isPlaying = NO;
    if (self.voiceExpression)
    {
        Number *voice = [self.voiceExpression evaluateNumberWithRunner:runner min:0 max:AudioNumVoices - 1];
        if (runner.error)
        {
            return nil;
        }
        
        isPlaying = [runner.audioPlayer voiceIsPlayingQueue:voice.intValue];
    }
    else
    {
        for (int i = 0; i < AudioNumVoices; i++)
        {
            if ([runner.audioPlayer voiceIsPlayingQueue:i])
            {
                isPlaying = YES;
                break;
            }
        }
    }
    return [runner.numberPool numberWithValue:(isPlaying ? 0 : -1)]; // opposite result => isPlaying != soundEnd
}

@end



@implementation LayerNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumLayers - 1];
    if (runner.error)
    {
        return nil;
    }
    
    runner.renderer.layerIndex = n.intValue;
    
    [runner next];
    return nil;
}

@end



@implementation GetNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.fromXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.fromYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.toYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    int maxPixel = runner.renderer.size - 1;
    
    Number *fromX = [self.fromXExpression evaluateNumberWithRunner:runner min:0 max:maxPixel];
    Number *fromY = [self.fromYExpression evaluateNumberWithRunner:runner min:0 max:maxPixel];
    Number *toX = [self.toXExpression evaluateNumberWithRunner:runner min:0 max:maxPixel];
    Number *toY = [self.toYExpression evaluateNumberWithRunner:runner min:0 max:maxPixel];
    if (runner.error)
    {
        return nil;
    }
    
    [runner.renderer getScreenFromX:fromX.intValue Y:fromY.intValue toX:toX.intValue Y:toY.intValue];
    
    [runner next];
    return nil;
}

@end

@implementation PutNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.yExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.srcXExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.srcYExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.srcWidthExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.srcHeightExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.transparencyExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *x = [self.xExpression evaluateWithRunner:runner];
    Number *y = [self.yExpression evaluateWithRunner:runner];
    Number *trans = [self.transparencyExpression evaluateNumberWithRunner:runner min:-1 max:15];
    
    if (runner.error)
    {
        return nil;
    }
    
    int transInt = (trans ? trans.intValue : -1);
    
    if (self.srcXExpression)
    {
        int maxSize = runner.renderer.size;
        Number *srcX = [self.srcXExpression evaluateNumberWithRunner:runner min:0 max:maxSize - 1];
        Number *srcY = [self.srcYExpression evaluateNumberWithRunner:runner min:0 max:maxSize - 1];
        Number *srcW = [self.srcWidthExpression evaluateNumberWithRunner:runner min:0 max:maxSize];
        Number *srcH = [self.srcHeightExpression evaluateNumberWithRunner:runner min:0 max:maxSize];
        
        if (runner.error)
        {
            return nil;
        }
        
        [runner.renderer putScreenX:x.intValue Y:y.intValue srcX:srcX.intValue srcY:srcY.intValue srcWidth:srcW.intValue srcHeight:srcH.intValue transparency:transInt];
    }
    else
    {
        [runner.renderer putScreenX:x.intValue Y:y.intValue srcX:0 srcY:0 srcWidth:0 srcHeight:0 transparency:transInt];
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
    /*Number *port = */[self.portExpression evaluateNumberWithRunner:runner min:0 max:0];
    if (runner.error)
    {
        return nil;
    }
    
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
    return [runner.numberPool numberWithValue:(result ? -1 : 0)];
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
    /*Number *port = */[self.portExpression evaluateNumberWithRunner:runner min:0 max:0];
    Number *button = [self.buttonExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    BOOL result = NO;
    switch (button.intValue)
    {
        case 0:
        {
            BOOL downA = [runner.delegate isButtonDown:ButtonTypeA];
            BOOL downB = [runner.delegate isButtonDown:ButtonTypeB];
            result = downA || downB;
            if (self.tap && result && (runner.buttonATapped || runner.buttonBTapped))
            {
                result = NO;
            }
            runner.buttonATapped = downA;
            runner.buttonBTapped = downB;
            break;
        }
        case 1:
        {
            BOOL down = [runner.delegate isButtonDown:ButtonTypeA];
            result = down;
            if (self.tap && result && runner.buttonATapped)
            {
                result = NO;
            }
            runner.buttonATapped = down;
            break;
        }
        case 2:
        {
            BOOL down = [runner.delegate isButtonDown:ButtonTypeB];
            result = down;
            if (self.tap && result && runner.buttonBTapped)
            {
                result = NO;
            }
            runner.buttonBTapped = down;
            break;
        }
        default:
            runner.error = [NSError invalidParameterErrorWithNode:self value:button.intValue];
            return nil;
    }
    return [runner.numberPool numberWithValue:(result ? -1 : 0)];
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
    Number *x = [self.xExpression evaluateWithRunner:runner];
    Number *y = [self.yExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    return [runner.numberPool numberWithValue:([runner.renderer colorAtX:x.intValue Y:y.intValue])];
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
    if (runner.error)
    {
        return nil;
    }
    
    NSString *string = ([value isKindOfClass:[NSString class]]) ? (NSString *)value : [NSString stringWithFormat:@"%@", value];
    int width = [runner.renderer widthForText:string];
    return [runner.numberPool numberWithValue:width];
}

@end



@implementation SpriteValueNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    if (runner.error)
    {
        return nil;
    }
    
    Sprite *sprite = [runner.renderer spriteAtIndex:n.intValue];
    if (self.type == 'X')
    {
        return [runner.numberPool numberWithValue:sprite->x];
    }
    if (self.type == 'Y')
    {
        return [runner.numberPool numberWithValue:sprite->y];
    }
    if (self.type == 'I')
    {
        return [runner.numberPool numberWithValue:(sprite->visible ? sprite->image : -1)];
    }
    return [runner.numberPool numberWithValue:(0)];
}

@end



@implementation SpriteHitNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.nExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.otherNExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.lastNExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *n = [self.nExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
    int first = 0;
    int last = RendererNumSprites - 1;
    
    if (self.otherNExpression)
    {
        Number *otherN = [self.otherNExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
        first = otherN.intValue;
        if (self.lastNExpression)
        {
            Number *lastN = [self.lastNExpression evaluateNumberWithRunner:runner min:0 max:RendererNumSprites - 1];
            last = lastN.intValue;
        }
        else
        {
            last = first;
        }
    }
    if (runner.error)
    {
        return nil;
    }
    
    for (int i = first; i <= last; i++)
    {
        if ([runner.renderer checkCollisionBetweenSprite:n.intValue andSprite:i])
        {
            runner.lastSpriteHit = i;
            return [runner.numberPool numberWithValue:-1];
        }
    }
    
    return [runner.numberPool numberWithValue:0];
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
        case TTypeSymHit: // sprite collision, not maths at all
            result = runner.lastSpriteHit;
            break;
        default:
            break;
    }
    return [runner.numberPool numberWithValue:result];
}

@end



@implementation Maths1Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *x = [self.xExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
                runner.error = [NSError invalidParameterErrorWithNode:self value:value];
                return nil;
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
                runner.error = [NSError invalidParameterErrorWithNode:self value:value];
                return nil;
            }
            result = sqrtf(value);
            break;
        case TTypeSymTan:
            result = tanf(value);
            break;
        default:
            break;
    }
    return [runner.numberPool numberWithValue:result];
}

@end



@implementation Maths2Node

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.xExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
    [self.yExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *x = [self.xExpression evaluateWithRunner:runner];
    Number *y = [self.xExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    float valueX = x.floatValue;
    float valueY = y.floatValue;
    float result = 0;
    switch (self.type)
    {
        case TTypeSymMin:
            result = MIN(valueX, valueY);
            break;
        case TTypeSymMax:
            result = MAX(valueX, valueY);
            break;
        default:
            break;
    }
    return [runner.numberPool numberWithValue:result];
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
    Number *number = [self.numberExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    if (number.intValue < 0)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:number.intValue];
        return nil;
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
    Number *number = [self.numberExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    NSUInteger len = string.length;
    if (number.intValue < 0)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:number.intValue];
        return nil;
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
    Number *position = [self.positionExpression evaluateWithRunner:runner];
    Number *number = [self.numberExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    NSUInteger len = string.length;
    if (position.intValue < 1)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:position.intValue];
        return nil;
    }
    if (number.intValue < 1)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:number.intValue];
        return nil;
    }
    if (position.intValue - 1 > len)
    {
        return @"";
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
    Number *position = [self.positionExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    NSUInteger len = string.length;
    
    if (position.intValue < 1)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:position.intValue];
        return nil;
    }
    if (position.intValue > len)
    {
        return [runner.numberPool numberWithValue:0];
    }
    
    NSRange range = [string rangeOfString:search options:0 range:NSMakeRange(position.intValue - 1, len - position.intValue + 1)];
    if (range.location == NSNotFound)
    {
        return [runner.numberPool numberWithValue:0];
    }
    return [runner.numberPool numberWithValue:(range.location + 1)];
}

@end



@implementation ChrNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.asciiExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *ascii = [self.asciiExpression evaluateNumberWithRunner:runner min:0 max:127];
    if (runner.error)
    {
        return nil;
    }
    
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
    if (runner.error)
    {
        return nil;
    }
    
    if (string.length < 1)
    {
        runner.error = [NSError invalidParameterErrorWithNode:self value:0];
        return nil;
    }
    unichar character = [string characterAtIndex:0];
    return [runner.numberPool numberWithValue:(int)character];
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
    if (runner.error)
    {
        return nil;
    }
    
    return [runner.numberPool numberWithValue:string.length];
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
    if (runner.error)
    {
        return nil;
    }
    
    return [runner.numberPool numberWithValue:string.floatValue];
}

@end



@implementation StrNode

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass
{
    [self.numberExpression prepareWithRunnable:runnable pass:pass canBeString:NO];
}

- (id)evaluateWithRunner:(Runner *)runner
{
    Number *number = [self.numberExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
    Number *number = [self.numberExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
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
                    runnable.error = [NSError typeMismatchErrorWithNode:self];
                    return;
                }
                break;

            default:
                if (leftReturnsString || rightReturnsString)
                {
                    runnable.error = [NSError typeMismatchErrorWithNode:self];
                    return;
                }
        }
    }
}

- (id)evaluateWithRunner:(Runner *)runner
{
    id leftValue = [self.leftExpression evaluateWithRunner:runner];
    id rightValue = [self.rightExpression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    BOOL leftIsString = [leftValue isKindOfClass:[NSString class]];
    BOOL rightIsString = [rightValue isKindOfClass:[NSString class]];
    
    switch (self.type)
    {
        case TTypeSymOpOr: {
            int leftInt = ((Number *)leftValue).intValue;
            int rightInt = ((Number *)rightValue).intValue;
            return [runner.numberPool numberWithValue:(leftInt | rightInt)];
        }
        case TTypeSymOpXor: {
            int leftInt = ((Number *)leftValue).intValue;
            int rightInt = ((Number *)rightValue).intValue;
            return [runner.numberPool numberWithValue:(leftInt ^ rightInt)];
        }
        case TTypeSymOpAnd: {
            int leftInt = ((Number *)leftValue).intValue;
            int rightInt = ((Number *)rightValue).intValue;
            return [runner.numberPool numberWithValue:(leftInt & rightInt)];
        }
        case TTypeSymOpPlus: {
            if (leftIsString || rightIsString)
            {
                return [NSString stringWithFormat:@"%@%@", leftValue, rightValue];
            }
            else
            {
                float result = ((Number *)leftValue).floatValue + ((Number *)rightValue).floatValue;
                return [runner.numberPool numberWithValue:result];
            }
        }
        case TTypeSymOpMinus: {
            float result = ((Number *)leftValue).floatValue - ((Number *)rightValue).floatValue;
            return [runner.numberPool numberWithValue:result];
        }
        case TTypeSymOpMul: {
            float result = ((Number *)leftValue).floatValue * ((Number *)rightValue).floatValue;
            return [runner.numberPool numberWithValue:result];
        }
        case TTypeSymOpDiv: {
            float rightFloat = ((Number *)rightValue).floatValue;
            if (rightFloat == 0.0)
            {
                runner.error = [NSError divisionByZeroErrorWithNode:self];
                return [runner.numberPool numberWithValue:0];
            }
            float result = ((Number *)leftValue).floatValue / rightFloat;
            return [runner.numberPool numberWithValue:result];
        }
        case TTypeSymOpMod: {
            int rightInt = ((Number *)rightValue).intValue;
            if (rightInt == 0)
            {
                runner.error = [NSError divisionByZeroErrorWithNode:self];
                return [runner.numberPool numberWithValue:0];
            }
            int result = ((Number *)leftValue).intValue % rightInt;
            return [runner.numberPool numberWithValue:result];
        }
        case TTypeSymOpPow: {
            int result = powf(((Number *)leftValue).floatValue, ((Number *)rightValue).floatValue);
            return [runner.numberPool numberWithValue:result];
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
                result = ((Number *)leftValue).floatValue == ((Number *)rightValue).floatValue;
            }
            if (self.type == TTypeSymOpUneq)
            {
                result = !result;
            }
            return [runner.numberPool numberWithValue:(result ? -1 : 0)];
        }
        case TTypeSymOpGr: {
            BOOL result = ((Number *)leftValue).floatValue > ((Number *)rightValue).floatValue;
            return [runner.numberPool numberWithValue:(result ? -1 : 0)];
        }
        case TTypeSymOpLe: {
            BOOL result = ((Number *)leftValue).floatValue < ((Number *)rightValue).floatValue;
            return [runner.numberPool numberWithValue:(result ? -1 : 0)];
        }
        case TTypeSymOpGrEq: {
            BOOL result = ((Number *)leftValue).floatValue >= ((Number *)rightValue).floatValue;
            return [runner.numberPool numberWithValue:(result ? -1 : 0)];
        }
        case TTypeSymOpLeEq: {
            BOOL result = ((Number *)leftValue).floatValue <= ((Number *)rightValue).floatValue;
            return [runner.numberPool numberWithValue:(result ? -1 : 0)];
        }
        default: {
            // invalid
        }
    }
    return [runner.numberPool numberWithValue:0];
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
    Number *value = [self.expression evaluateWithRunner:runner];
    if (runner.error)
    {
        return nil;
    }
    
    switch (self.type)
    {
        case TTypeSymOpPlus:
            return value;
        case TTypeSymOpMinus:
            return [runner.numberPool numberWithValue:(-value.floatValue)];
        case TTypeSymOpNot:
            return [runner.numberPool numberWithValue:(~value.intValue)];
        default: {
            // invalid
        }
    }
    return value;
}

@end
