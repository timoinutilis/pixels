//
//  Runner.h
//  Pixels
//
//  Created by Timo Kloss on 23/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerDelegate.h"

@class Node;

@interface Runner : NSObject

@property (weak) id<RunnerDelegate> delegate;

- (instancetype)initWithNodes:(NSArray *)nodes;
- (BOOL)isFinished;
- (void)runCommand;
- (void)next;
- (void)exitLoop;
- (void)resetSequence;
- (void)addSequenceWithNodes:(NSArray *)nodes isLoop:(BOOL)isLoop parent:(Node *)parent;

- (void)setValue:(id)value forVariable:(NSString *)identifier;
- (id)valueOfVariable:(NSString *)identifier;

@end


@interface Sequence : NSObject
@property NSArray *nodes;
@property NSUInteger index;
@property BOOL isLoop;
@property Node *parent;
@end