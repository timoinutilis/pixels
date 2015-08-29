//
//  NumberPool.h
//  Pixels
//
//  Created by Timo Kloss on 20/8/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Number : NSObject

@property float floatValue;
@property int intValue;
@property (readonly) NSString *stringValue;

+ (Number *)numberWithValue:(float)value;

@end


@interface NumberPool : NSObject

- (void)reset;
- (Number *)numberWithValue:(float)value;

@end
