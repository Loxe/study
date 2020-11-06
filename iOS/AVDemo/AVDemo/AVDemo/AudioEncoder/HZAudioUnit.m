//
//  HZAudioUnit.m
//  AVDemo
//
//  Created by 黄镇 on 2020/9/13.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "HZAudioUnit.h"
#import "SQAudioPlay.h"
#import "SQAVConfig.h"

#define kOutputBus 0
#define kInputBus 1

#define subPathPCM @"/Documents/abb.pcm"
#define stroePath [NSHomeDirectory() stringByAppendingString:subPathPCM]

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData);
static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData);

@interface HZAudioUnit()
@property (nonatomic, strong) SQAudioPlay *pcmPlayer;
@end

@implementation HZAudioUnit

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    NSError *error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [session setActive:YES error:nil];
    if (error) {
        NSLog(@"error: %@", error.userInfo);
    }
    
    self.pcmPlayer = [[SQAudioPlay alloc] initWithConfig:[SQAudioConfig defaultConifg]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:stroePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:stroePath error:nil];
    }
    
    OSStatus status;
    AudioComponentInstance audioUnit;
    
    // Describe audio component
    // 描述音频元件
    AudioComponentDescription desc;
    desc.componentType                      = kAudioUnitType_Output;
    desc.componentSubType                   = kAudioUnitSubType_RemoteIO;
    desc.componentFlags                     = 0;
    desc.componentFlagsMask                 = 0;
    desc.componentManufacturer              = kAudioUnitManufacturer_Apple;
    
    // Get component
    // 获得一个元件
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    // 获得 Audio Unit
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    self.audioUnit = audioUnit;
    
//    UInt32 busCount = 2;
//    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount));
//    checkStatus(status);
    
    UInt32 busCount2 = 0;
    UInt32 ioDataSize = sizeof(busCount2);
    AudioUnitGetProperty(audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount2, &ioDataSize);
    NSLog(@"busCount:%d", busCount2);
    
    // Enable IO for recording
    // 为录制打开 IO
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    // 为播放打开 IO
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Describe format
    // 描述格式
    _audioFormat.mSampleRate                 = 44100.00;
    _audioFormat.mFormatID                   = kAudioFormatLinearPCM;
    _audioFormat.mFormatFlags                = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsPacked;
    _audioFormat.mFramesPerPacket            = 1;
    _audioFormat.mChannelsPerFrame           = 1;
    _audioFormat.mBitsPerChannel             = 16;
    _audioFormat.mBytesPerPacket             = 2;
    _audioFormat.mBytesPerFrame              = 2;
    
    // Apply format
    // 设置格式
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &_audioFormat,
                                  sizeof(_audioFormat));
    checkStatus(status);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &_audioFormat,
                                  sizeof(_audioFormat));
    checkStatus(status);
    
    
    // Set input callback
    // 设置数据采集回调函数
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    // 设置声音输出回调函数。当speaker需要数据时就会调用回调函数去获取数据。它是 "拉" 数据的概念。
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    // 关闭为录制分配的缓冲区（我们想使用我们自己分配的）
//    flag = 0;
//    status = AudioUnitSetProperty(audioUnit,
//                                  kAudioUnitProperty_ShouldAllocateBuffer,
//                                  kAudioUnitScope_Output,
//                                  kInputBus,
//                                  &flag,
//                                  sizeof(flag));
    
    //Allocate our own buffers if we want
    
    // Initialise
    // 初始化
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    //Initialise也可以用以下代码
//    UInt32 category = kAudioSessionCategory_PlayAndRecord;
//    status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
//    checkStatus(status);
//    status = 0;
//    status = AudioSessionSetActive(YES);
//    checkStatus(status);
//    status = AudioUnitInitialize(_audioUnit);
//    checkStatus(status);
    
    return self;
}

// 检测状态
void checkStatus(OSStatus status) {
    if(status!=0)
        printf("Error: %d\n", (int)status);
}

//开启 Audio Unit
- (void)start {
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    checkStatus(status);
}

//关闭 Audio Unit
- (void)stop {
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    checkStatus(status);
}

//结束 Audio Unit
- (void)finished {
    AudioComponentInstanceDispose(_audioUnit);
}

@end


static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    // TODO:
    // 使用 inNumberFrames 计算有多少数据是有效的
    // 在 AudioBufferList 里存放着更多的有效空间
    
    HZAudioUnit *hzAudioUnit = (__bridge HZAudioUnit *)inRefCon;
//    AudioBufferList bufferList = {
//        //bufferList里存放着一堆 buffers, buffers的长度是动态的。
//        .mNumberBuffers = 1,
//        .mBuffers[0].mDataByteSize = sizeof(SInt16) * inNumberFrames,
//        .mBuffers[0].mNumberChannels = 1,
//        .mBuffers[0].mData = (SInt16 *)malloc(sizeof(SInt16) * inNumberFrames),
//    };
//    memset(bufferList.mBuffers[0].mData, 0, sizeof(SInt16) * inNumberFrames);
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = 0;
    
    // 获得录制的采样数据
    OSStatus status = AudioUnitRender(hzAudioUnit.audioUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      kInputBus,
                                      inNumberFrames,
                                      &(bufferList));
    checkStatus(status);
    
    //hzAudioUnit.bufferList = bufferList;
    
    // 现在，我们想要的采样数据已经在bufferList中的buffers中了。
    //DoStuffWithTheRecordedAudio(bufferList);
    //NSLog(@"ioActionFlags:%d inBusNumber:%d inNumberFrames:%d ioData:%p", *ioActionFlags, inBusNumber, inNumberFrames, ioData);
    //NSLog(@" 1 %p", bufferList.mBuffers[0].mData);
    
    /*NSData *data = [NSData dataWithBytes:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize];
    // 经调试,这个数据写到文件,用其它方式播是正常的, 但直接在播放回调函数里播,又播不出来
    //[hzAudioUnit.pcmPlayer playPCMData:data];
    
    NSString *savePath = stroePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath] == false)
    {
        [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
    }
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
    [handle seekToEndOfFile];
    [handle writeData:data];*/
    
    return noErr;
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    
    // Notes: ioData 包括了一堆 buffers
    // 尽可能多的向ioData中填充数据，记得设置每个buffer的大小要与buffer匹配好。
    HZAudioUnit *hzAudioUnit = (__bridge HZAudioUnit *)inRefCon;
    //NSLog(@"ioActionFlags:%d inBusNumber:%d inNumberFrames:%d mNumberBuffers:%d ioData:%p", *ioActionFlags, inBusNumber, inNumberFrames, ioData->mNumberBuffers, ioData);
    /// 直接播自己采集的数据不行, 但播AVFoundation采集的数据正常
    for (int i = 0; i < ioData->mNumberBuffers; i++) {
        AudioBuffer buffer = ioData->mBuffers[i];
        if (hzAudioUnit.bufferList.mBuffers[0].mDataByteSize) {
            UInt32 size = (UInt32)MIN(buffer.mDataByteSize, hzAudioUnit.bufferList.mBuffers[0].mDataByteSize);
            memcpy(buffer.mData, hzAudioUnit.bufferList.mBuffers[0].mData, size);
            free(hzAudioUnit.bufferList.mBuffers[0].mData);
            buffer.mDataByteSize = size;
            //NSLog(@" 2 %p", buffer.mData);
        } else {
            buffer.mDataByteSize = 0;
            *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
        }
    }
    
    return noErr;
}
