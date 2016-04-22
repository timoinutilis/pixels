//
//  Runner.h
//  Pixels
//
//  Created by Timo Kloss on 23/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerDelegate.h"

@class Node, OnXGotoNode, Renderer, AudioPlayer, Runnable, Token, NumberPool, VariableManager, Sequence, SequenceTreeSnapshot;

@interface Runner : NSObject

@property (weak) id<RunnerDelegate> delegate;
@property (nonatomic) NSError *error;
@property Renderer *renderer;
@property AudioPlayer *audioPlayer;
@property NSUInteger dataNodeIndex;
@property NSUInteger dataConstantIndex;
@property (readonly) VariableManager *variables;
@property (readonly) NumberPool *numberPool;
@property (readonly) NSMutableArray <NSMutableArray <NSString *> *> *transferLines;
@property OnXGotoNode *currentOnEndGoto;
@property OnXGotoNode *currentOnPauseGoto;
@property BOOL endRequested;
@property int lastSpriteHit;
@property BOOL buttonATapped;
@property BOOL buttonBTapped;
@property (nonatomic) int writeMaxCount;
@property CFAbsoluteTime bootTime;

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

- (void)restoreDataTransfer;
- (void)restoreDataLabel:(NSString *)label atToken:(Token *)token;
- (Node *)readDataAtToken:(Token *)token;
- (void)beginWriteDataWithForcedNewLine:(BOOL)forceNewLine;
- (void)writeDataValue:(id)value disableNewLine:(BOOL)disableNewLine;
- (NSString *)transferResult;

- (void)wait:(NSTimeInterval)time stopBlock:(BOOL(^)())block;

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
