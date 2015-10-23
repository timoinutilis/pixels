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

typedef NS_ENUM(NSInteger, RecordingMode) {
    RecordingModeNone,
    RecordingModeScreen,
    RecordingModeScreenAndMic
};

@interface Runnable : NSObject

@property (readonly) NSArray *nodes;
@property (readonly) NSMutableDictionary *labels;
@property (readonly) NSMutableArray *dataNodes;
@property NSArray *transferDataNodes;
@property BOOL usesGamepad;
@property BOOL usesSound;
@property RecordingMode recordingMode;
@property (nonatomic) NSError *error;

- (instancetype)initWithNodes:(NSArray *)nodes;
- (void)prepare;
- (void)prepareNodes:(NSArray *)nodes pass:(PrePass)pass;

@end
