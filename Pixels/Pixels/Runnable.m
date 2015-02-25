//
//  Runnable.m
//  Pixels
//
//  Created by Timo Kloss on 8/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "Runnable.h"
#import "Node.h"

@implementation Runnable

- (instancetype)initWithNodes:(NSArray *)nodes
{
    if (self = [super init])
    {
        _nodes = nodes;
        _labels = [NSMutableDictionary dictionary];
        _dataNodes = [NSMutableArray array];
    }
    return self;
}

- (void)prepare
{
    [self prepareNodes:self.nodes pass:PrePassInit];
    [self prepareNodes:self.nodes pass:PrePassCheckSemantic];
}

- (void)prepareNodes:(NSArray *)nodes pass:(PrePass)pass
{
    for (Node *node in nodes)
    {
        [node prepareWithRunnable:self pass:pass];
    }
}

@end
