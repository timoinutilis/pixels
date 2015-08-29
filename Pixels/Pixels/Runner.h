//
//  Runner.h
//  Pixels
//
//  Created by Timo Kloss on 23/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerDelegate.h"

@class Node, OnXGotoNode, Renderer, AudioPlayer, Runnable, VariableNode, Token, NumberPool;

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
- (int)intAtOffset:(NSUInteger)offset;
@end


@interface Runner : NSObject

@property (weak) id<RunnerDelegate> delegate;
@property (nonatomic) NSError *error;
@property Renderer *renderer;
@property AudioPlayer *audioPlayer;
@property int printLine;
@property NSUInteger dataNodeIndex;
@property NSUInteger dataConstantIndex;
@property (readonly) NumberPool *numberPool;
@property (readonly) NSMutableArray *transferStrings;
@property OnXGotoNode *currentOnEndGoto;
@property OnXGotoNode *currentOnPauseGoto;
@property BOOL endRequested;
@property int lastSpriteHit;
@property BOOL buttonATapped;
@property BOOL buttonBTapped;

- (instancetype)initWithRunnable:(Runnable *)runnable;
- (BOOL)isFinished;
- (void)runCommand;
- (void)end;
- (void)next;
- (void)exitLoopAtToken:(Token *)token;
- (void)resetSequence;
- (void)gotoLabel:(NSString *)label isGosub:(BOOL)isGosub atToken:(Token *)token;
- (void)returnFromGosubAtToken:(Token *)token;
- (void)returnFromGosubToLabel:(NSString *)label atToken:(Token *)token;
- (void)addSequenceWithNodes:(NSArray *)nodes isLoop:(BOOL)isLoop parent:(Node *)parent;
- (BOOL)handlePauseButton;

- (void)loadPersistentVariables:(NSDictionary *)dict;
- (NSDictionary *)getPersistentVariables;
- (void)persistVariable:(VariableNode *)variable asArray:(BOOL)asArray;

- (void)dimVariable:(VariableNode *)variable;
- (void)setValue:(id)value forVariable:(VariableNode *)variable;
- (id)valueOfVariable:(VariableNode *)variable;
- (ArrayVariable *)arrayOfVariable:(VariableNode *)variable;

- (void)restoreDataTransfer;
- (void)restoreDataLabel:(NSString *)label atToken:(Token *)token;
- (Node *)readDataAtToken:(Token *)token;

- (void)wait:(NSTimeInterval)time stopBlock:(BOOL(^)())block;

@end
