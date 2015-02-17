//
//  Runner.h
//  Pixels
//
//  Created by Timo Kloss on 23/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerDelegate.h"

@class Node, Renderer, Runnable, VariableNode;

@interface Runner : NSObject

@property (weak) id<RunnerDelegate> delegate;
@property Renderer *renderer;
@property int printLine;

- (instancetype)initWithRunnable:(Runnable *)runnable;
- (BOOL)isFinished;
- (void)runCommand;
- (void)end;
- (void)next;
- (BOOL)exitLoop;
- (void)resetSequence;
- (BOOL)gotoLabel:(NSString *)label isGosub:(BOOL)isGosub;
- (BOOL)returnFromGosub;
- (void)addSequenceWithNodes:(NSArray *)nodes isLoop:(BOOL)isLoop parent:(Node *)parent;

- (void)dimVariable:(VariableNode *)variable;
- (void)setValue:(id)value forVariable:(VariableNode *)variable;
- (id)valueOfVariable:(VariableNode *)variable;

@end


@interface Sequence : NSObject
@property NSArray *nodes;
@property NSUInteger index;
@property BOOL isLoop;
@property Node *parent;
@end

@interface SequenceTreeSnapshot : NSObject
@property (readonly) NSMutableArray *sequencesStack;
@property (readonly) NSMutableArray *indexes;
- (instancetype)initWithSequencesStack:(NSMutableArray *)stack;
@end

@interface ArrayVariable : NSObject
@property (readonly) NSMutableArray *values;
@property (readonly) NSArray *sizes;
- (instancetype)initWithSizes:(NSArray *)sizes;
- (NSUInteger)offsetForIndexes:(NSArray *)indexes;
@end
