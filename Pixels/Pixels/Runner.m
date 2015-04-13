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
#import "Runnable.h"
#import "ProgramException.h"

NSTimeInterval const RunnerOnEndTimeOut = 2;

@interface Runner ()
@property Runnable *runnable;
@property NSMutableArray *sequencesStack;
@property NSMutableDictionary *numberVariables;
@property NSMutableDictionary *stringVariables;
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
        
        self.numberVariables = [NSMutableDictionary dictionary];
        self.stringVariables = [NSMutableDictionary dictionary];
        self.sequencesStack = [NSMutableArray array];
        self.gosubStack = [NSMutableArray array];
        _transferStrings = [NSMutableArray array];
        
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
    if (self.timeWhenOnEndStarted != 0 && CFAbsoluteTimeGetCurrent() - self.timeWhenOnEndStarted > RunnerOnEndTimeOut)
    {
        NSException *exception = [ProgramException exceptionWithName:@"OnEndTimeout"
                                                              reason:@"ON END timed out"
                                                               token:self.currentOnEndGoto.token];
        @throw exception;
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
            NSException *exception = [ProgramException exceptionWithName:@"ExitOutsideLoop"
                                                                  reason:@"EXIT outside of loop"
                                                                   token:token];
            @throw exception;
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
    
    NSException *exception = [ProgramException exceptionWithName:@"UnaccessibleLabel"
                                                          reason:[NSString stringWithFormat:@"Unaccessible label %@", label]
                                                           token:token];
    @throw exception;
}

- (void)returnFromGosubAtToken:(Token *)token
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
        return;
    }
    
    NSException *exception = [ProgramException exceptionWithName:@"ReturnWithoutGosub"
                                                          reason:@"RETURN without GOSUB"
                                                           token:token];
    @throw exception;
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

- (void)dimVariable:(VariableNode *)variable
{
    NSArray *sizes = [variable indexesWithRunner:self add:1];
    
    // check bounds
    for (NSUInteger i = 0; i < sizes.count; i++)
    {
        int size = [sizes[i] intValue];
        if (size < 1)
        {
            NSException *exception = [ProgramException invalidParameterExceptionWithNode:variable value:size - 1];

            @throw exception;
        }
    }
    
    ArrayVariable *arrayVariable = [[ArrayVariable alloc] initWithSizes:sizes];
    
    if (!arrayVariable.values)
    {
        NSException *exception = [ProgramException exceptionWithName:@"ArrayTooLarge"
                                                              reason:@"Array too large"
                                                               token:variable.token];
        @throw exception;
    }
    
    NSMutableDictionary *dict = variable.isString ? self.stringVariables : self.numberVariables;
    
    if (dict[variable.identifier])
    {
        NSException *exception = [ProgramException exceptionWithName:@"VariableAlreadyUsed"
                                                              reason:[NSString stringWithFormat:@"Variable %@ already used", variable.identifier]
                                                               token:variable.token];
        @throw exception;
    }
    
    dict[variable.identifier] = arrayVariable;
}

- (void)setValue:(id)value forVariable:(VariableNode *)variable
{
    [self accessVariable:variable setValue:value];
}

- (id)valueOfVariable:(VariableNode *)variable
{
    id value = [self accessVariable:variable setValue:nil];
    if (!value || value == [NSNull null])
    {
        value = variable.isString ? @"" : @(0);
    }
    return value;
}

- (ArrayVariable *)arrayOfVariable:(VariableNode *)variable
{
    NSMutableDictionary *dict = variable.isString ? self.stringVariables : self.numberVariables;
    BOOL isArrayVariable = [dict[variable.identifier] isKindOfClass:[ArrayVariable class]];
    if (!isArrayVariable)
    {
        NSException *exception = [ProgramException exceptionWithName:@"VariableNotDimensionalized"
                                                              reason:[NSString stringWithFormat:@"Variable %@ not dimensionalized", variable.identifier]
                                                               token:variable.token];
        @throw exception;
    }
    if (variable.indexExpressions)
    {
        NSException *exception = [ProgramException exceptionWithName:@"NoIndexAllowed" reason:@"No index allowed" token:variable.token];
        @throw exception;
    }
    return dict[variable.identifier];
}

- (id)accessVariable:(VariableNode *)variable setValue:(id)setValue
{
    NSMutableDictionary *dict = variable.isString ? self.stringVariables : self.numberVariables;
    BOOL isArrayVariable = [dict[variable.identifier] isKindOfClass:[ArrayVariable class]];
    
    id getValue = nil;
    
    if (variable.indexExpressions)
    {
        // accessing array variable
        if (!isArrayVariable)
        {
            NSException *exception = [ProgramException exceptionWithName:@"VariableNotDimensionalized"
                                                                  reason:[NSString stringWithFormat:@"Variable %@ not dimensionalized", variable.identifier]
                                                                   token:variable.token];
            @throw exception;
        }
        ArrayVariable *arrayVariable = dict[variable.identifier];
        
        // check dimensions
        if (variable.indexExpressions.count != arrayVariable.sizes.count)
        {
            NSException *exception = [ProgramException exceptionWithName:@"IncorrectDimensions"
                                                                  reason:@"Incorrect number of dimensions"
                                                                   token:variable.token];
            @throw exception;
        }
        
        NSArray *indexes = [variable indexesWithRunner:self add:0];
        
        // check bounds
        for (NSUInteger i = 0; i < indexes.count; i++)
        {
            int index = [indexes[i] intValue];
            if (index < 0 || index >= [arrayVariable.sizes[i] intValue])
            {
                NSException *exception = [ProgramException exceptionWithName:@"IndexOutOfBounds"
                                                                      reason:[NSString stringWithFormat:@"Index out of bounds (%d)", index]
                                                                       token:variable.token];
                @throw exception;
            }
        }
        
        NSUInteger offset = [arrayVariable offsetForIndexes:indexes];
        if (setValue)
        {
            arrayVariable.values[offset] = setValue;
        }
        else
        {
            getValue = arrayVariable.values[offset];
        }
    }
    else
    {
        // accessing simple variable
        if (isArrayVariable)
        {
            NSException *exception = [ProgramException exceptionWithName:@"ArrayVariableWithoutIndex"
                                                                  reason:[NSString stringWithFormat:@"Array variable %@ without index", variable.identifier]
                                                                   token:variable.token];
            @throw exception;
        }
        
        if (setValue)
        {
            dict[variable.identifier] = setValue;
        }
        else
        {
            getValue = dict[variable.identifier];
        }
    }
    
    return getValue;
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
    
    NSException *exception = [ProgramException exceptionWithName:@"OutOfData" reason:@"Out of data" token:token];
    @throw exception;
    
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


@implementation ArrayVariable

- (instancetype)initWithSizes:(NSArray *)sizes
{
    if (self = [super init])
    {
        _sizes = sizes;
        NSUInteger capacity = [self calcCapacity];
        if (capacity <= 16384)
        {
            _values = [NSMutableArray arrayWithCapacity:capacity];
            for (NSUInteger i = 0; i < capacity; i++)
            {
                _values[i] = [NSNull null];
            }
        }
    }
    return self;
}

- (NSUInteger)calcCapacity
{
    NSUInteger capacity = 1;
    for (NSNumber *dimensionSize in _sizes)
    {
        capacity *= dimensionSize.intValue;
    }
    return capacity;
}

- (NSUInteger)offsetForIndexes:(NSArray *)indexes
{
    NSUInteger offset = 0;
    int factor = 1;
    for (int i = (int)self.sizes.count - 1; i >= 0; i--)
    {
        if (i < indexes.count)
        {
            offset += [indexes[i] intValue] * factor;
        }
        factor *= [self.sizes[i] intValue];
    }
    return offset;
}

- (int)intAtOffset:(NSUInteger)offset;
{
    NSNumber *number = _values[offset];
    if (number && (id)number != [NSNull null])
    {
        return number.intValue;
    }
    return 0;
}

@end
