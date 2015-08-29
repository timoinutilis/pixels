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
#import "AudioPlayer.h"
#import "VariableManager.h"
#import "NumberPool.h"
#import "Runnable.h"
#import "NSError+LowResCoder.h"

NSTimeInterval const RunnerOnEndTimeOut = 2;


@interface Runner ()
@property Runnable *runnable;
@property NSMutableArray *sequencesStack;
@property NSMutableArray *gosubStack;
@property BOOL dataTransferEnabled;
@property NSTimeInterval timeWhenOnEndStarted;
@end

@implementation Runner

- (instancetype)initWithRunnable:(Runnable *)runnable
{
    if (self = [self init])
    {
        self.runnable = runnable;
        self.renderer = [[Renderer alloc] init];
        self.audioPlayer = [[AudioPlayer alloc] init];
        
        self.sequencesStack = [NSMutableArray array];
        self.gosubStack = [NSMutableArray array];
        _variables = [[VariableManager alloc] initWithRunner:self];
        _numberPool = [[NumberPool alloc] init];
        _transferStrings = [NSMutableArray array];
                
        [self addSequenceWithNodes:runnable.nodes isLoop:NO parent:nil];
    }
    return self;
}

- (void)setError:(NSError *)error
{
    // don't overwrite existing error
    if (!_error)
    {
        _error = error;
    }
}

- (BOOL)isFinished
{
    return self.sequencesStack.count == 0;
}

- (void)runCommand
{
    if (self.timeWhenOnEndStarted != 0 && CFAbsoluteTimeGetCurrent() - self.timeWhenOnEndStarted > RunnerOnEndTimeOut)
    {
        self.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"ON END timed out" token:self.currentOnEndGoto.token];
        return;
    }
    else if (self.endRequested && self.timeWhenOnEndStarted == 0)
    {
        if (self.currentOnEndGoto)
        {
            self.timeWhenOnEndStarted = CFAbsoluteTimeGetCurrent();
            [self gotoLabel:self.currentOnEndGoto.label isGosub:NO atToken:self.currentOnEndGoto.token];
        }
        else
        {
            [self end];
        }
    }
    else
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
    [self.numberPool reset];
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

- (void)exitLoopAtToken:(Token *)token
{
    Sequence *sequence = self.sequencesStack.lastObject;
    while (!sequence.isLoop)
    {
        [self.sequencesStack removeLastObject];
        sequence = self.sequencesStack.lastObject;
        if (!sequence)
        {
            self.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"EXIT outside of loop" token:token];
            return;
        }
    }
    [self.sequencesStack removeLastObject];
    [self next];
}

- (void)resetSequence
{
    Sequence *sequence = self.sequencesStack.lastObject;
    sequence.index = 0;
}

- (void)gotoLabel:(NSString *)label isGosub:(BOOL)isGosub atToken:(Token *)token
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
                return;
            }
        }
        [self.sequencesStack removeLastObject];
        sequence = self.sequencesStack.lastObject;
    }

    self.error = [NSError programErrorWithCode:LRCErrorCodeRuntime
                                        reason:[NSString stringWithFormat:@"Unaccessible label %@", label]
                                         token:token];
}

- (void)returnFromGosubAtToken:(Token *)token
{
    [self returnFromGosubToLabel:nil atToken:token];
}

- (void)returnFromGosubToLabel:(NSString *)label atToken:(Token *)token
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
        
        if (label)
        {
            [self gotoLabel:label isGosub:NO atToken:token];
        }
        else
        {
            [self next];
        }
        return;
    }
    
    self.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"RETURN without GOSUB" token:token];
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

- (BOOL)handlePauseButton
{
    if (self.currentOnPauseGoto)
    {
        [self gotoLabel:self.currentOnPauseGoto.label isGosub:NO atToken:self.currentOnPauseGoto.token];
        return YES;
    }
    return NO;
}

- (void)restoreDataTransfer
{
    self.dataTransferEnabled = YES;
    self.dataNodeIndex = 0;
    self.dataConstantIndex = 0;
}

- (void)restoreDataLabel:(NSString *)label atToken:(Token *)token
{
    self.dataTransferEnabled = NO;
    if (label)
    {
        Node *labelNode = self.runnable.labels[label];
        self.dataNodeIndex = [self.runnable.dataNodes indexOfObject:labelNode];
    }
    else
    {
        self.dataNodeIndex = 0;
    }
    self.dataConstantIndex = 0;
}

- (Node *)readDataAtToken:(Token *)token
{
    NSArray *dataNodes = self.dataTransferEnabled ? self.runnable.transferDataNodes : self.runnable.dataNodes;
    while (self.dataNodeIndex < dataNodes.count)
    {
        Node *node = dataNodes[self.dataNodeIndex];
        if ([node isKindOfClass:[DataNode class]])
        {
            DataNode *dataNode = (DataNode *)node;
            if (self.dataConstantIndex < dataNode.constants.count)
            {
                Node *constant = dataNode.constants[self.dataConstantIndex];
                self.dataConstantIndex++;
                return constant;
            }
        }
        self.dataNodeIndex++;
        self.dataConstantIndex = 0;
    }
    
    self.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"Out of data" token:token];
    return nil;
}

- (void)wait:(NSTimeInterval)time stopBlock:(BOOL(^)())block
{
    NSTimeInterval endTime = CFAbsoluteTimeGetCurrent() + time;
    NSTimeInterval maxSleep = block ? 0.02 : 0.2;
    if (self.timeWhenOnEndStarted > 0)
    {
        endTime = MIN(self.timeWhenOnEndStarted + RunnerOnEndTimeOut, endTime);
    }
    
    BOOL stop = NO;
    do
    {
        [NSThread sleepForTimeInterval:MIN(time, maxSleep)];
        time = endTime - CFAbsoluteTimeGetCurrent();
        if (block)
        {
            stop = block();
        }
    } while (time > 0 && (!self.endRequested || self.timeWhenOnEndStarted > 0) && !stop);
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


