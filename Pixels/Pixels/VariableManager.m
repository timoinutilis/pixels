//
//  Variables.m
//  Pixels
//
//  Created by Timo Kloss on 29/8/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "VariableManager.h"
#import "Node.h"
#import "NSError+LowResCoder.h"
#import "NumberPool.h"
#import "Runner.h"

@interface VariableManager()
@property (weak) Runner *runner;
@property NSMutableDictionary *numberVariables;
@property NSMutableDictionary *stringVariables;
@property NSDictionary *loadedPersistentVariables;
@property NSMutableSet *persistentNumberVariables;
@property NSMutableSet *persistentStringVariables;
@end


@implementation VariableManager

- (instancetype)initWithRunner:(Runner *)runner
{
    if (self = [self init])
    {
        self.runner = runner;
        
        self.numberVariables = [NSMutableDictionary dictionary];
        self.stringVariables = [NSMutableDictionary dictionary];
        
        self.loadedPersistentVariables = [NSDictionary dictionary];
        self.persistentNumberVariables = [NSMutableSet set];
        self.persistentStringVariables = [NSMutableSet set];
    }
    return self;
}

- (void)loadPersistentVariables:(NSDictionary *)dict
{
    self.loadedPersistentVariables = dict;
}

- (NSDictionary *)getPersistentVariables
{
    if (self.runner.error) return nil;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *key = nil;
    
    for (key in self.persistentNumberVariables)
    {
        if (self.numberVariables[key])
        {
            dict[key] = [self persistentObjectForValue:self.numberVariables[key]];
        }
    }
    for (key in self.persistentStringVariables)
    {
        if (self.stringVariables[key])
        {
            NSString *pKey = [NSString stringWithFormat:@"%@$", key];
            dict[pKey] = [self persistentObjectForValue:self.stringVariables[key]];
        }
    }
    
    return dict;
}

- (id)persistentObjectForValue:(id)value
{
    if ([value isKindOfClass:[ArrayVariable class]])
    {
        //TODO arrays
        return @[];
    }
    return value;
}

- (void)persistVariable:(VariableNode *)variable asArray:(BOOL)asArray
{
    NSMutableDictionary *varDict = nil;
    NSString *persKey = nil;
    if (variable.isString)
    {
        varDict = self.stringVariables;
        persKey = [NSString stringWithFormat:@"%@$", variable.identifier];
    }
    else
    {
        varDict = self.numberVariables;
        persKey = variable.identifier;
    }
    
    // check if variable can be used persistent
    if (!asArray)
    {
        id value = varDict[variable.identifier];
        if (value)
        {
            self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime
                                                       reason:[NSString stringWithFormat:@"Variable %@ already used", variable.identifier]
                                                        token:variable.token];
        }
    }
    
    // register variable name as persistent
    if (variable.isString)
    {
        [self.persistentStringVariables addObject:variable.identifier];
    }
    else
    {
        [self.persistentNumberVariables addObject:variable.identifier];
    }
    
    // restore persistent value
    id persistantValue = self.loadedPersistentVariables[persKey];
    if (persistantValue)
    {
        if (asArray)
        {
            //TODO
        }
        else
        {
            [self setValue:persistantValue forVariable:variable];
        }
    }
}

- (void)dimVariable:(VariableNode *)variable
{
    NSArray *sizes = [variable indexesWithRunner:self.runner isDim:YES];
    
    // check bounds
    for (NSUInteger i = 0; i < sizes.count; i++)
    {
        int size = [sizes[i] intValue];
        if (size < 1)
        {
            self.runner.error = [NSError invalidParameterErrorWithNode:variable value:size - 1];
            return;
        }
    }
    
    ArrayVariable *arrayVariable = [[ArrayVariable alloc] initWithSizes:sizes];
    
    if (!arrayVariable.values)
    {
        self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"Array too large" token:variable.token];
        return;
    }
    
    NSMutableDictionary *dict = variable.isString ? self.stringVariables : self.numberVariables;
    
    if (dict[variable.identifier])
    {
        self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime
                                                   reason:[NSString stringWithFormat:@"Variable %@ already used", variable.identifier]
                                                    token:variable.token];
        return;
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
        value = variable.isString ? @"" : [self.runner.numberPool numberWithValue:0];
    }
    return value;
}

- (ArrayVariable *)arrayOfVariable:(VariableNode *)variable
{
    NSMutableDictionary *dict = variable.isString ? self.stringVariables : self.numberVariables;
    BOOL isArrayVariable = [dict[variable.identifier] isKindOfClass:[ArrayVariable class]];
    if (!isArrayVariable)
    {
        self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime
                                                   reason:[NSString stringWithFormat:@"Variable %@ not dimensionalized", variable.identifier]
                                                    token:variable.token];
        return nil;
    }
    if (variable.indexExpressions)
    {
        self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"No index allowed" token:variable.token];
        return nil;
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
            self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime
                                                reason:[NSString stringWithFormat:@"Variable %@ not dimensionalized", variable.identifier]
                                                 token:variable.token];
            return nil;
        }
        ArrayVariable *arrayVariable = dict[variable.identifier];
        
        // check dimensions
        if (variable.indexExpressions.count != arrayVariable.sizes.count)
        {
            self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime reason:@"Incorrect number of dimensions" token:variable.token];
            return nil;
        }
        
        NSArray *indexes = [variable indexesWithRunner:self.runner isDim:NO];
        
        // check bounds
        for (NSUInteger i = 0; i < indexes.count; i++)
        {
            int index = [indexes[i] intValue];
            if (index < 0 || index >= [arrayVariable.sizes[i] intValue])
            {
                self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime
                                                           reason:[NSString stringWithFormat:@"Index out of bounds (%d)", index]
                                                            token:variable.token];
                return nil;
            }
        }
        
        NSUInteger offset = [arrayVariable offsetForIndexes:indexes];
        if (setValue)
        {
            arrayVariable.values[offset] = [self valueWith:setValue variable:arrayVariable.values[offset]];
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
            self.runner.error = [NSError programErrorWithCode:LRCErrorCodeRuntime
                                                       reason:[NSString stringWithFormat:@"Array variable %@ without index", variable.identifier]
                                                        token:variable.token];
            return nil;
        }
        
        if (setValue)
        {
            dict[variable.identifier] = [self valueWith:setValue variable:dict[variable.identifier]];
        }
        else
        {
            getValue = dict[variable.identifier];
        }
    }
    
    return getValue;
}

- (id)valueWith:(id)value variable:(id)varValue
{
    if ([value isKindOfClass:[Number class]])
    {
        if (!varValue || varValue == [NSNull null])
        {
            varValue = [[Number alloc] init];
        }
        ((Number *)varValue).floatValue = ((Number *)value).floatValue;
        return varValue;
    }
    return value;
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
