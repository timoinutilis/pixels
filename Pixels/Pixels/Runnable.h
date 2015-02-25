//
//  Runnable.h
//  Pixels
//
//  Created by Timo Kloss on 8/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PrePass) {
    PrePassInit,
    PrePassCheckSemantic
};

@interface Runnable : NSObject

@property (readonly) NSArray *nodes;
@property (readonly) NSMutableDictionary *labels;
@property (readonly) NSMutableArray *dataNodes;
@property NSArray *transferDataNodes;

- (instancetype)initWithNodes:(NSArray *)nodes;
- (void)prepare;
- (void)prepareNodes:(NSArray *)nodes pass:(PrePass)pass;

@end
