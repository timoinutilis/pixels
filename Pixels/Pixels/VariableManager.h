//
//  Variables.h
//  Pixels
//
//  Created by Timo Kloss on 29/8/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ArrayVariable, VariableNode, Runner;


@interface VariableManager : NSObject

- (instancetype)initWithRunner:(Runner *)runner;

- (void)loadPersistentVariables:(NSDictionary *)dict;
- (NSDictionary *)getPersistentVariables;
- (void)persistVariable:(VariableNode *)variable asArray:(BOOL)asArray;

- (void)dimVariable:(VariableNode *)variable;
- (void)setValue:(id)value forVariable:(VariableNode *)variable;
- (id)valueOfVariable:(VariableNode *)variable;
- (ArrayVariable *)arrayOfVariable:(VariableNode *)variable;

@end


@interface ArrayVariable : NSObject
@property (readonly) NSMutableArray *values;
@property (readonly) NSArray *sizes;
@property (readonly) BOOL isString;
- (instancetype)initWithSizes:(NSArray *)sizes isString:(BOOL)isString;
- (NSUInteger)offsetForIndexes:(NSArray *)indexes;
- (int)intAtOffset:(NSUInteger)offset;
- (NSDictionary *)dictionary;
- (void)loadFromDictionary:(NSDictionary *)dict;
@end
