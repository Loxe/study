//
//  HZVideoToolboxDecoder.m
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/10/20.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "HZVideoToolboxDecoder.h"


@interface HZVideoToolboxDecoder ()
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDescriptionOut;
@property (nonatomic, assign) VTDecompressionSessionRef decodeSession;
@end

@implementation HZVideoToolboxDecoder

void videoDecompressionOutputCallback(void * CM_NULLABLE decompressionOutputRefCon,
                                      void * CM_NULLABLE sourceFrameRefCon,
                                      OSStatus status,
                                      VTDecodeInfoFlags infoFlags,
                                      CM_NULLABLE CVImageBufferRef imageBuffer,
                                      CMTime presentationTimeStamp,
                                      CMTime presentationDuration) {
    if (status != noErr) {
        NSLog(@"VideoToolboxDecoder callback error %d", (int)status);
        return;
    }
    //NSLog(@"解码出 %p", imageBuffer);
    
    HZVideoToolboxDecoder *decoder = (__bridge HZVideoToolboxDecoder *)(decompressionOutputRefCon);
    // 解码后是在一个串行队列里, 解码的时候设置的
    if (decoder.delegate) {
        [decoder.delegate videoToolboxDecoder:decoder didGetImageBuffer:imageBuffer];
    }
    //释放数据, VideoToolbox内部会释放, 这里释放会崩溃
    //CVPixelBufferRelease(imageBuffer);
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)freeSessionData {
    if (self.formatDescriptionOut) {
        CFRelease(self.formatDescriptionOut);
        self.formatDescriptionOut = NULL;
    }
    if (self.decodeSession) {
        CFRelease(self.decodeSession);
        self.decodeSession = NULL;
    }
}

- (void)dealloc {
    [self freeSessionData];
}

- (void)decodeVideoWithVideoInfoData:(HZVideoInfoData)videoInfoData {
    if (!self.decodeSession) {
        [self createDecompressionSessionWithVideoInfoData:(HZVideoInfoData)videoInfoData];
    }
    if (!self.decodeSession) {
        return;
    }
    
    CMBlockBufferRef blockBuffer;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         videoInfoData.packetData,
                                                         videoInfoData.packetDataSize,
                                                         kCFAllocatorNull,
                                                         NULL,
                                                         0,
                                                         videoInfoData.packetDataSize,
                                                         0,
                                                         &blockBuffer);
    if (status != kCMBlockBufferNoErr) {
        NSLog(@"CMBlockBufferCreateWithMemoryBlock error %d", (int)status);
        return;
    }
    
    CMSampleBufferRef sampleBuffer;
    const size_t sampleSizeArray[] = {videoInfoData.packetDataSize};
    status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                       blockBuffer,
                                       self.formatDescriptionOut,
                                       1,
                                       1,
                                       &(videoInfoData.timingInfo),
                                       1,
                                       sampleSizeArray,
                                       &sampleBuffer);
    
    VTDecodeInfoFlags  infoFlag = kVTDecodeInfo_Asynchronous;
    status = VTDecompressionSessionDecodeFrame(self.decodeSession, sampleBuffer, kVTDecodeFrame_1xRealTimePlayback, NULL, &infoFlag);
    if (status == kVTInvalidSessionErr) {
        NSLog(@"VTDecompressionSessionDecodeFrame InvalidSessionErr %d", (int)status);
    } else if (status == kVTVideoDecoderBadDataErr) {
        NSLog(@"VTDecompressionSessionDecodeFrame BadData %d", (int)status);
    } else if (status != noErr) {
        NSLog(@"VTDecompressionSessionDecodeFrame error %d", (int)status);
    }
}

- (void)createDecompressionSessionWithVideoInfoData:(HZVideoInfoData)videoInfoData {
    // 参考了 http://www.ffmpeg.org/doxygen/3.4/videotoolbox_8c_source.html
    // 回调
    VTDecompressionOutputCallbackRecord callbackRecord;
    callbackRecord.decompressionOutputCallback = videoDecompressionOutputCallback;
    callbackRecord.decompressionOutputRefCon = (__bridge void * _Nullable)(self);
    // 目标像素格式
    CFNumberRef w = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &videoInfoData.width);
    CFNumberRef h = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &videoInfoData.height);
    OSType pix_fmt = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CFNumberRef cv_pix_fmt = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pix_fmt);
    CFMutableDictionaryRef buffer_attributes = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                         4,
                                                                         &kCFTypeDictionaryKeyCallBacks,
                                                                         &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef io_surface_properties = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                             0,
                                                                             &kCFTypeDictionaryKeyCallBacks,
                                                                             &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(buffer_attributes, kCVPixelBufferPixelFormatTypeKey, cv_pix_fmt);
    CFDictionarySetValue(buffer_attributes, kCVPixelBufferIOSurfacePropertiesKey, io_surface_properties);
    CFDictionarySetValue(buffer_attributes, kCVPixelBufferWidthKey, w);
    CFDictionarySetValue(buffer_attributes, kCVPixelBufferHeightKey, h);
    CFRelease(io_surface_properties);
    CFRelease(cv_pix_fmt);
    CFRelease(w);
    CFRelease(h);
    
    CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                   videoInfoData.codecType,
                                   videoInfoData.width,
                                   videoInfoData.height,
                                   videoInfoData.videoDecoderSpecification,
                                   &_formatDescriptionOut);
    // 创建Session
    OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                   self.formatDescriptionOut,
                                                   videoInfoData.videoDecoderSpecification,
                                                   buffer_attributes,
                                                   &callbackRecord,
                                                   &_decodeSession);
    if (status != noErr) {
        NSLog(@"VTDecompressionSessionCreate error: %d", (int)status);
        [self freeSessionData];
    }
    CFRelease(buffer_attributes);
}

@end
