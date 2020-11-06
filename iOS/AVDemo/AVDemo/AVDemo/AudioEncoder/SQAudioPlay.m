//
//  SQAudioPlay.m
//  AVDemo
//
//  Created by Sem on 2020/8/14.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "SQAudioPlay.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "SQAVConfig.h"
#import "SQAudioDataQueue.h"

#define MIN_SIZE_PER_FRAME 2048 //每帧最小数据长度

static const int kNumberBuffers_play = 3;

typedef struct AQPlayerSatae{
    AudioStreamBasicDescription   mStreamBasicDescription;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers_play];       // 4
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
}AQPlayerState;

static void TMAudioQueueOutputCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);


@interface SQAudioPlay ()
@property (nonatomic, assign) AQPlayerState playState;
@property (nonatomic, strong) SQAudioConfig *config;
@property (nonatomic, assign) BOOL isPlaying;
@end

@implementation SQAudioPlay
- (instancetype)initWithConfig:(SQAudioConfig *)config{
    if(self = [super init]){
        _config = config;
        AudioStreamBasicDescription dataFormat = {0}; // 采样率 ：Hz
        dataFormat.mSampleRate = (Float64)_config.sampleRate;
        dataFormat.mChannelsPerFrame = (UInt32)_config.channelCount; // 每一帧数据中的通道数，单声道为1，立体声为2
        dataFormat.mFormatID = kAudioFormatLinearPCM; // 数据的类型，PCM,AAC等
        dataFormat.mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked);// 每种格式特定的标志，无损编码 ，0表示没有
        dataFormat.mFramesPerPacket = 1; // 一个数据包中的帧数， 每个packet的帧数。 如果是未压缩的音频数据，值是1。 动态帧率格式，这个值是一个较大的固定数字， 比如说AAC的1024。 如果是动态大小帧数（比如Ogg格式）设置为0。
        dataFormat.mBitsPerChannel = 16; // 每个通道中的位数，1byte = 8bit
        dataFormat.mBytesPerFrame = dataFormat.mBitsPerChannel / 8 * dataFormat.mChannelsPerFrame; // 每一帧中的字节数
        dataFormat.mBytesPerPacket = dataFormat.mBytesPerFrame * dataFormat.mFramesPerPacket; // 一个数据包中的字节数
        dataFormat.mReserved =  0; // 8字节对齐，填0
        AQPlayerState state = {0};
        state.mStreamBasicDescription = dataFormat;
        _playState = state;
        [self setupSeesion];
        OSStatus status = AudioQueueNewOutput(&_playState.mStreamBasicDescription, TMAudioQueueOutputCallback, NULL, NULL, NULL, 0, &_playState.mQueue);
        if (status != noErr) {
            NSError *error = [[NSError alloc] initWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            NSLog(@"Error: AudioQueue create error = %@", [error description]);
            return self;
        }
        
        [self setupVoice:1];
        _isPlaying = false;
    }
    return self;
}

- (void)setupSeesion {
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        NSLog(@"Error: audioQueue palyer AVAudioSession error, error: %@", error);
    }
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"Error: audioQueue palyer AVAudioSession error, error: %@", error);
    }
}

/**播放pcm*/
- (void)playPCMData:(NSData *)data{
    AudioQueueBufferRef inBuffer;
    AudioQueueAllocateBuffer(_playState.mQueue, MIN_SIZE_PER_FRAME, &inBuffer);
    memcpy(inBuffer->mAudioData, data.bytes, data.length);
    inBuffer->mAudioDataByteSize = (UInt32)data.length;
    OSStatus status = AudioQueueEnqueueBuffer(_playState.mQueue, inBuffer, 0, NULL);
    //NSLog(@"AudioQueueEnqueueBuffer %p", inBuffer);
    if (status != noErr) {
        NSLog(@"Error: audio queue palyer  enqueue error: %d",(int)status);
    }
    
    //开始播放或录制音频
    /*
     参数1:要开始的音频队列
     参数2:音频队列应开始的时间。
     要指定相对于关联音频设备时间线的开始时间，请使用audioTimestamp结构的msampletime字段。使用NULL表示音频队列应尽快启动
     */
    AudioQueueStart(_playState.mQueue, NULL);
}

/** 设置音量增量 0.0 - 1.0 */
- (void)setupVoice:(Float32)gain {
    Float32 gain0 = gain;
    if(gain < 0){
        gain0 = 0 ;
    } else if (gain0 > 1) {
        gain0 = 1;
    }
    AudioQueueSetParameter(_playState.mQueue, kAudioQueueParam_Volume, gain0);
}

/**销毁 */
- (void)dispose{
    AudioQueueStop(_playState.mQueue, true);
    AudioQueueDispose(_playState.mQueue, true);
}

@end



static void TMAudioQueueOutputCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    //NSLog(@"TMAudioQueueOutputCallback %p", inBuffer);
    AudioQueueFreeBuffer(inAQ, inBuffer);
}
