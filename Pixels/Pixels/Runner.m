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
@property NSMutableDictionary *variables;
@end

@implementation Runner

- (instancetype)initWithRunnable:(Runnable *)runnable
{
    if (self = [self init])
    {
        self.runnable = runnable;
        self.renderer = [[Renderer alloc] init];
        self.variables = [NSMutableDictionary dictionary];
        self.sequencesStack = [NSMutableArray array];
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
    Node *node = sequence.nodes[sequence.index];
    [node evaluateWithRunner:self];
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

- (void)addSequenceWithNodes:(NSArray *)nodes isLoop:(BOOL)isLoop parent:(Node *)parent
{
    Sequence *sequence = [[Sequence alloc] init];
    sequence.nodes = nodes;
    sequence.index = 0;
    sequence.isLoop = isLoop;
    sequence.parent = parent;
    [self.sequencesStack addObject:sequence];
}

- (void)setValue:(id)value forVariable:(NSString *)identifier
{
    self.variables[identifier] = value;
}

- (id)valueOfVariable:(NSString *)identifier
{
    id value = self.variables[identifier];
    if (value)
    {
        return value;
    }
    return @(0);
}

@end


@implementation Sequence

@end
