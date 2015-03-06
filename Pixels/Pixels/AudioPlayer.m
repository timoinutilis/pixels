//
//  AudioPlayer.m
//  Pixels
//
//  Created by Timo Kloss on 5/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

static void OutputBufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer)
{
    int16_t *audioData = inCompleteAQBuffer->mAudioData;
    int len = inCompleteAQBuffer->mAudioDataBytesCapacity / 2;
    
    for (int i = 0; i < len; i++)
    {
        audioData[i] = arc4random() % 0x00FF - 0x007F;
    }
    
    AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
}

@implementation AudioPlayer {
    AudioStreamBasicDescription _dataFormat;
    AudioQueueRef _queue;
}

- (instancetype)init
{
    if (self = [super init])
    {
        // AudioStreamBasicDescription
        _dataFormat.mSampleRate = 44100;
        _dataFormat.mFormatID = kAudioFormatLinearPCM;
        _dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
        _dataFormat.mBytesPerPacket = 2;
        _dataFormat.mFramesPerPacket = 1;
        _dataFormat.mBytesPerFrame = 2;
        _dataFormat.mChannelsPerFrame = 1;
        _dataFormat.mBitsPerChannel = 16;
        _dataFormat.mReserved = 0;
    }
    return self;
}

- (void)start
{
    OSStatus result;
    result = AudioQueueNewOutput(&_dataFormat, OutputBufferCallback, NULL, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_queue);
    result = AudioQueueStart(_queue, NULL);
}

- (void)stop
{
    AudioQueueStop(_queue, TRUE);
    AudioQueueDispose(_queue, TRUE);
    _queue = NULL;
}

@end
