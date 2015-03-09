//
//  AudioPlayer.m
//  Pixels
//
//  Created by Timo Kloss on 5/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioSession.h>

int const AudioNumVoices = 3;

typedef struct PlayerSystem {
    float sampleRate;
    Voice voices[AudioNumVoices];
    int16_t noise[4096];
} PlayerSystem;

static void RenderAudio(AudioQueueBufferRef buffer, PlayerSystem *player);
static void OutputBufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer);


@implementation AudioPlayer {
    AudioStreamBasicDescription _dataFormat;
    AudioQueueRef _queue;
    PlayerSystem _player;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _player.sampleRate = 22050;
        
        // AudioStreamBasicDescription
        _dataFormat.mSampleRate = _player.sampleRate;
        _dataFormat.mFormatID = kAudioFormatLinearPCM;
        _dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger| kLinearPCMFormatFlagIsPacked;
        _dataFormat.mBytesPerPacket = 2;
        _dataFormat.mFramesPerPacket = 1;
        _dataFormat.mBytesPerFrame = 2;
        _dataFormat.mChannelsPerFrame = 1;
        _dataFormat.mBitsPerChannel = 16;
        _dataFormat.mReserved = 0;
        
        for (int i = 0; i < AudioNumVoices; i++)
        {
            Voice *voice = &_player.voices[i];
            voice->wave = i == WaveTypeTriangle;
            voice->frequence = 440;
            voice->x = 0;
            voice->volume = 0;
        }
        
        for (int i = 0; i < 4096; i++)
        {
            _player.noise[i] = rand() & 0xFFFF;
        }
    }
    return self;
}

- (void)start
{
    OSStatus result;
    
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setPreferredSampleRate:_player.sampleRate error:nil];
    _player.sampleRate = session.sampleRate;
    _dataFormat.mSampleRate = session.sampleRate;
    
    result = AudioQueueNewOutput(&_dataFormat, OutputBufferCallback, &_player, NULL/*CFRunLoopGetCurrent()*/, kCFRunLoopCommonModes, 0, &_queue);
    
    AudioQueueBufferRef buffer;
    for (int i = 0; i < 3; i++)
    {
        result = AudioQueueAllocateBuffer(_queue, 1024, &buffer);
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
        RenderAudio(buffer, &_player);
        result = AudioQueueEnqueueBuffer(_queue, buffer, 0, NULL);
    }
    
    result = AudioQueueStart(_queue, NULL);
}

- (void)stop
{
    AudioQueueStop(_queue, TRUE);
    AudioQueueDispose(_queue, TRUE);
    _queue = NULL;
}

- (Voice *)voiceAtIndex:(int)index
{
    return &_player.voices[index];
}

@end

static void RenderAudio(AudioQueueBufferRef buffer, PlayerSystem *player)
{
    int16_t *audioData = buffer->mAudioData;
    int len = buffer->mAudioDataBytesCapacity >> 1;
    int16_t sumSample, voiceSample;
    int i, v;
    Voice *voice;
    
    for (i = 0; i < len; i++)
    {
        sumSample = 0;
        for (v = 0; v < AudioNumVoices; v++)
        {
            voice = &player->voices[v];
            switch (voice->wave)
            {
                case WaveTypePulse:
                    voice->x = fmodf(voice->x, 1.0f);
                    voiceSample = voice->x < 0.5f ? SHRT_MAX : SHRT_MIN;
                    break;
                case WaveTypeTriangle:
                    voice->x = fmodf(voice->x, 1.0f);
                    voiceSample = (voice->x < 0.5f ? voice->x * 4.0f - 1.0f : 1.0f - (voice->x - 0.5f) * 4.0f) * SHRT_MAX;
                    break;
                case WaveTypeSawtooth:
                    voice->x = fmodf(voice->x, 1.0f);
                    voiceSample = (voice->x * 2.0f - 1.0f) * SHRT_MAX;
                    break;
                case WaveTypeNoise:
                    voice->x = fmodf(voice->x, 512.0f); // 4096.0f / 8.0f
                    voiceSample = player->noise[(int)(voice->x * 8.0f)];
                    break;
            }
            sumSample += (voiceSample * voice->volume) >> 6; // 4 + 2
            voice->x = voice->x + voice->frequence / player->sampleRate;
        }
        audioData[i] = sumSample;
    }
}

static void OutputBufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer)
{
    RenderAudio(inCompleteAQBuffer, inUserData);
    AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
}
