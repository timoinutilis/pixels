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
int const AudioNumSoundDefs = 16;
int const AudioFilterBufSize = 7;

typedef struct AudioSequence {
    SoundNote notes[128];
    int writeIndex;
    int readIndex;
    int ticks;
} AudioSequence;

typedef struct Voice {
    int soundDef;
    double frequency;
    BOOL gate;
    double gateTime;
    double x;
} Voice;

typedef struct PlayerSystem {
    double sampleRate;
    SoundDef soundDefs[AudioNumSoundDefs];
    Voice voices[AudioNumVoices];
    AudioSequence sequences[AudioNumVoices];
    double frameCount;
    int16_t noise[4096];
    int32_t filterBuffer[AudioFilterBufSize];
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
            voice->soundDef = 0;
            voice->frequency = 440;
            voice->x = 0;
            voice->gate = FALSE;
            voice->gateTime = 0;
            
            AudioSequence *sequence = &_player.sequences[i];
            sequence->writeIndex = 0;
            sequence->readIndex = 0;
            sequence->ticks = 0;
        }
        
        for (int i = 0; i < AudioNumSoundDefs; i++)
        {
            SoundDef *def = &_player.soundDefs[i];
            def->wave = i % 4;
            def->pulseWidth = 0.5;
            def->bendTime = 1.0;
            def->pitchBend = 0;
        }
        
        for (int i = 0; i < 4096; i++)
        {
            _player.noise[i] = rand() & 0xFFFF;
        }
        
        for (int i = 0; i < AudioFilterBufSize; i++)
        {
            _player.filterBuffer[i] = 0;
        }
        
        _player.frameCount = 0.0;
    }
    return self;
}

- (void)start
{
    if (!_isActive)
    {
        _isActive = YES;
        
        OSStatus result;
        
        AVAudioSession* session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryAmbient error:nil];
        [session setPreferredSampleRate:_player.sampleRate error:nil];
        _player.sampleRate = session.sampleRate;
        _dataFormat.mSampleRate = session.sampleRate;
        
        result = AudioQueueNewOutput(&_dataFormat, OutputBufferCallback, &_player, NULL, kCFRunLoopCommonModes, 0, &_queue);
        
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
}

- (void)stop
{
    if (_isActive)
    {
        _isActive = NO;

        AudioQueueStop(_queue, TRUE);
        AudioQueueDispose(_queue, TRUE);
        _queue = NULL;
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
}

- (SoundDef *)soundDefAtIndex:(int)index
{
    return &_player.soundDefs[index];
}

- (SoundNote *)nextNoteForVoice:(int)voice
{
    AudioSequence *sequence = &_player.sequences[voice];
    SoundNote *note = &sequence->notes[sequence->writeIndex];
    sequence->writeIndex++;
    if (sequence->writeIndex == 128)
    {
        sequence->writeIndex = 0;
    }
    return note;
}

@end

static void UpdateNotes(PlayerSystem *player)
{
    int v;
    AudioSequence *sequence;
    SoundNote *note;
    Voice *voice;
    
    // audio sequence
    for (v = 0; v < AudioNumVoices; v++)
    {
        sequence = &player->sequences[v];
        if (sequence->ticks > 0)
        {
            sequence->ticks--;
        }
        if (sequence->ticks == 0)
        {
            voice = &player->voices[v];
            if (sequence->readIndex != sequence->writeIndex)
            {
                // start note
                note = &sequence->notes[sequence->readIndex];
                if (note->pitch != 0)
                {
                    voice->frequency = 440.0 * pow(2.0, (note->pitch - 58) / 12.0);
                }
                if (note->soundDef != -1)
                {
                    voice->soundDef = note->soundDef;
                }
                voice->gate = (note->pitch != 0);
                voice->gateTime = 0.0;
                sequence->ticks = note->duration;
                
                sequence->readIndex++;
                if (sequence->readIndex == 128)
                {
                    sequence->readIndex = 0;
                }
            }
            else
            {
                //stop sound
                voice->gate = FALSE;
            }
        }
    }
}

static void RenderAudio(AudioQueueBufferRef buffer, PlayerSystem *player)
{
    int16_t *audioData = buffer->mAudioData;
    int len = buffer->mAudioDataBytesCapacity >> 1;
    int16_t sumSample, voiceSample;
    int i, v, f;
    double bendFactor, finalFrequency, finalPulseWidth;
    Voice *voice;
    SoundDef *def;
    double frameToUpdate = ceil(player->sampleRate / 24);
    
    // wave form
    for (i = 0; i < len; i++)
    {
        if (player->frameCount == 0.0)
        {
            UpdateNotes(player);
        }
        player->frameCount++;
        if (player->frameCount == frameToUpdate)
        {
            player->frameCount = 0.0;
        }
        
        sumSample = 0;
        for (v = 0; v < AudioNumVoices; v++)
        {
            voice = &player->voices[v];
            def = &player->soundDefs[voice->soundDef];

            bendFactor = voice->gateTime / def->bendTime / player->sampleRate;
            if (bendFactor > 1.0)
            {
                bendFactor = 1.0;
            }
            
            if (voice->gate)
            {
                switch (def->wave)
                {
                    case WaveTypeSawtooth:
                        voice->x = fmod(voice->x, 1.0);
                        voiceSample = (voice->x * 2.0 - 1.0) * SHRT_MAX;
                        break;
                    case WaveTypeTriangle:
                        voice->x = fmod(voice->x, 1.0);
                        voiceSample = (voice->x < 0.5 ? voice->x * 4.0 - 1.0 : 1.0 - (voice->x - 0.5) * 4.0) * SHRT_MAX;
                        break;
                    case WaveTypePulse:
                        voice->x = fmod(voice->x, 1.0);
                        finalPulseWidth = def->pulseWidth * pow(2.0, def->pulseBend * bendFactor);
                        if (finalPulseWidth > 0.9)
                        {
                            finalPulseWidth = 0.9;
                        }
                        else if (finalPulseWidth < 0.1)
                        {
                            finalPulseWidth = 0.1;
                        }
                        voiceSample = voice->x < finalPulseWidth ? SHRT_MAX : SHRT_MIN;
                        break;
                    case WaveTypeNoise:
                        voice->x = fmod(voice->x, 512.0); // 4096.0 / 8.0
                        voiceSample = player->noise[(int)(voice->x * 8.0)];
                        break;
                }
                sumSample += voiceSample >> 2; // lower volume
            }
            
            finalFrequency = voice->frequency * pow(2.0, def->pitchBend * bendFactor / 12.0);
            voice->x = voice->x + finalFrequency / player->sampleRate;
            voice->gateTime++;
        }
        
        // filter and store to buffer
        for (f = AudioFilterBufSize - 1; f > 0; f--)
        {
            player->filterBuffer[f] = player->filterBuffer[f - 1];
        }
        player->filterBuffer[0] = sumSample;

        audioData[i] = (  (player->filterBuffer[0] >> 3)
                        + (player->filterBuffer[1] >> 2)
                        + (player->filterBuffer[2] >> 1)
                        + (player->filterBuffer[3])
                        + (player->filterBuffer[4] >> 1)
                        + (player->filterBuffer[5] >> 2)
                        + (player->filterBuffer[6] >> 3)) / 3;
        
    }
}

static void OutputBufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer)
{
    RenderAudio(inCompleteAQBuffer, inUserData);
    AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
}
