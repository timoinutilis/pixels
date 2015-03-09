//
//  AudioPlayer.h
//  Pixels
//
//  Created by Timo Kloss on 5/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WaveType) {
    WaveTypePulse,
    WaveTypeTriangle,
    WaveTypeSawtooth,
    WaveTypeNoise
};

typedef struct Voice {
    WaveType wave;
    float frequence;
    int volume;
    float x;
} Voice;

extern int const AudioNumVoices;

@interface AudioPlayer : NSObject

- (void)start;
- (void)stop;
- (Voice *)voiceAtIndex:(int)index;

@end
