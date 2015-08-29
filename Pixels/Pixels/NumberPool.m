//
//  NumberPool.m
//  Pixels
//
//  Created by Timo Kloss on 20/8/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "NumberPool.h"

@implementation Number

+ (Number *)numberWithValue:(float)value
{
    Number *number = [[Number alloc] init];
    number.floatValue = value;
    return number;
}

- (void)setIntValue:(int)intValue
{
    _floatValue = intValue;
}

- (int)intValue
{
    return (int)_floatValue;
}

- (NSString *)stringValue
{
    return @(_floatValue).stringValue;
}

- (NSString *)description
{
    return self.stringValue;
}

@end


@interface NumberPool()
@property NSMutableArray *numbers;
@property int index;
@property int capacity;
@end

@implementation NumberPool

- (instancetype)init
{
    if (self = [super init])
    {
        _numbers = [NSMutableArray arrayWithCapacity:20];
    }
    return self;
}

- (void)reset
{
    _index = 0;
}

- (Number *)numberWithValue:(float)value
{
    Number *number = nil;
    if (_index >= _capacity)
    {
        number = [[Number alloc] init];
        [_numbers addObject:number];
        _capacity++;
    }
    else
    {
        number = _numbers[_index];
    }
    number.floatValue = value;
    _index++;
    return number;
}

@end
