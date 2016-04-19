//
//  AudioPlayer.h
//  Pixels
//
//  Created by Timo Kloss on 5/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WaveType) {
    WaveTypeSawtooth,
    WaveTypeTriangle,
    WaveTypePulse,
    WaveTypeNoise
};

typedef struct SoundDef {
    WaveType wave;
    double pulseWidth;
    double bendTime;
    int pitchBend;
    double pulseBend;
    double maxTime;
} SoundDef;

typedef struct SoundNote {
    int pitch;
    int duration;
    int soundDef;
} SoundNote;
                    
extern int const AudioNumVoices;
extern int const AudioNumSoundDefs;

@interface AudioPlayer : NSObject

@property (readonly) BOOL isActive;
@property double volume;

- (void)start;
- (void)stop;
- (SoundDef *)soundDefAtIndex:(int)index;
- (SoundNote *)nextNoteForVoice:(int)voice;
- (void)resetVoice:(int)voice;
- (void)setVoice:(int)voiceIndex pitch:(int)pitch soundDef:(int)def;
- (int)queueLengthOfVoice:(int)voiceIndex;

@end
