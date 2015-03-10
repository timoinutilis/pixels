//
//  AudioPlayer.h
//  Pixels
//
//  Created by Timo Kloss on 5/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WaveType) {
    WaveTypeNone = -1,
    WaveTypeTriangle = 0,
    WaveTypeSawtooth,
    WaveTypeNoise,
    WaveTypePulse50,
    WaveTypePulse25,
    WaveTypePulse12,
    WaveTypePulse6,
    WaveTypePulse3,
};

typedef struct AudioVoice {
    WaveType wave;
    float frequency;
    int volume;
    float x;
} AudioVoice;

typedef struct AudioNote {
    int pitch;
    int duration;
    int volume;
    WaveType wave;
} AudioNote;
                    
extern int const AudioNumVoices;

@interface AudioPlayer : NSObject

- (void)start;
- (void)stop;
- (AudioVoice *)voiceAtIndex:(int)index;
- (AudioNote *)nextNoteForVoice:(int)voice;

@end
