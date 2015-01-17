//
//  Runner.m
//  Pixels
//
//  Created by Timo Kloss on 23/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Runner.h"
#import "Node.h"
#import "Renderer.h"
#import "Runnable.h"

@interface Runner ()
@property Runnable *runnable;
@property NSMutableArray *sequencesStack;
@property NSMutableDictionary *numberVariables;
@property NSMutableDictionary *stringVariables;
@property NSMutableArray *gosubStack;
@end

@implementation Runner

- (instancetype)initWithRunnable:(Runnable *)runnable
{
    if (self = [self init])
    {
        self.runnable = runnable;
        self.renderer = [[Renderer alloc] init];
        self.numberVariables = [NSMutableDictionary dictionary];
        self.stringVariables = [NSMutableDictionary dictionary];
        self.sequencesStack = [NSMutableArray array];
        self.gosubStack = [NSMutableArray array];
        
        [self addSequenceWithNodes:runnable.nodes isLoop:NO parent:nil];
    }
    return self;
}

- (BOOL)isFinished
{
    return self.sequencesStack.count == 0;
}

- (void)runCommand
{
    Sequence *sequence = self.sequencesStack.lastObject;
    if (sequence.nodes.count > 0)
    {
        Node *node = sequence.nodes[sequence.index];
        [node evaluateWithRunner:self];
    }
    else
    {
        [self next];
    }
}

- (void)end
{
    [self.sequencesStack removeAllObjects];
}

- (void)next
{
    Sequence *sequence = self.sequencesStack.lastObject;
    sequence.index++;
    while (sequence && sequence.index >= sequence.nodes.count)
    {
        if (sequence.isLoop)
        {
            [sequence.parent endOfLoopWithRunner:self];
            break;
        }
        else
        {
            [self.sequencesStack removeLastObject];
            sequence = self.sequencesStack.lastObject;
            if (sequence)
            {
                sequence.index++;
            }
        }
    }
}

- (void)exitLoop
{
    Sequence *sequence = self.sequencesStack.lastObject;
    while (!sequence.isLoop)
    {
        [self.sequencesStack removeLastObject];
        sequence = self.sequencesStack.lastObject;
    }
    [self.sequencesStack removeLastObject];
    [self next];
}

- (void)resetSequence
{
    Sequence *sequence = self.sequencesStack.lastObject;
    sequence.index = 0;
}

- (BOOL)gotoLabel:(NSString *)label isGosub:(BOOL)isGosub
{
    if (isGosub)
    {
        // remember current position
        SequenceTreeSnapshot *snapshot = [[SequenceTreeSnapshot alloc] initWithSequencesStack:self.sequencesStack];
        [self.gosubStack addObject:snapshot];
    }
    
    Node *node = self.runnable.labels[label];
    Sequence *sequence = self.sequencesStack.lastObject;
    while (sequence)
    {
        for (NSUInteger i = 0; i < sequence.nodes.count; i++)
        {
            if (sequence.nodes[i] == node)
            {
                sequence.index = i;
                return YES;
            }
        }
        [self.sequencesStack removeLastObject];
        sequence = self.sequencesStack.lastObject;
    }
    return NO;
}

- (BOOL)returnFromGosub
{
    SequenceTreeSnapshot *snapshot = self.gosubStack.lastObject;
    if (snapshot)
    {
        [self.gosubStack removeLastObject];
        self.sequencesStack = snapshot.sequencesStack;
        for (NSUInteger i = 0; i < snapshot.indexes.count; i++)
        {
            Sequence *sequence = self.sequencesStack[i];
            sequence.index = [snapshot.indexes[i] integerValue];
        }
        [self next];
        return YES;
    }
    return NO;
}

- (void)addSequenceWithNodes:(NSArray *)nodes isLoop:(BOOL)isLoop parent:(Node *)parent
{
    Sequence *sequence = [[Sequence alloc] init];
    sequence.nodes = nodes;
    sequence.index = 0;
    sequence.isLoop = isLoop;
    sequence.parent = parent;
    [self.sequencesStack addObject:sequence];
}

- (void)setValue:(id)value forVariable:(VariableNode *)variable
{
    if (variable.isString)
    {
        self.stringVariables[variable.identifier] = value;
    }
    else
    {
        self.numberVariables[variable.identifier] = value;
    }
}

- (id)valueOfVariable:(VariableNode *)variable
{
    if (variable.isString)
    {
        NSString *value = self.stringVariables[variable.identifier];
        if (value)
        {
            return value;
        }
        return @"";
    }
    
    NSNumber *value = self.numberVariables[variable.identifier];
    if (value)
    {
        return value;
    }
    return @(0);
}

@end


@implementation Sequence

@end


@implementation SequenceTreeSnapshot

- (instancetype)initWithSequencesStack:(NSMutableArray *)stack
{
    if (self = [super init])
    {
        _sequencesStack = [NSMutableArray arrayWithArray:stack];
        _indexes = [NSMutableArray array];
        for (NSUInteger i = 0; i < stack.count; i++)
        {
            Sequence *sequence = stack[i];
            [_indexes addObject:@(sequence.index)];
        }
    }
    return self;
}

@end
