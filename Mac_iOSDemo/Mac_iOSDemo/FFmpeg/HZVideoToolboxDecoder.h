//
//  HZVideoToolboxDecoder.h
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/10/20.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct HZVideoInfoData {
    CMVideoCodecType codecType;
    BOOL hasSPSAndPPS;
    CFDictionaryRef videoDecoderSpecification;
    int32_t width;
    int32_t height;
    uint8_t *packetData;
    int packetDataSize;
    CMSampleTimingInfo timingInfo;
} HZVideoInfoData;


@class HZVideoToolboxDecoder;
@protocol HZVideoToolboxDecoderDelegate <NSObject>
- (void)videoToolboxDecoder:(HZVideoToolboxDecoder *)videoToolboxDecoder didGetImageBuffer:(CVPixelBufferRef)imageBuffer;
@end


@interface HZVideoToolboxDecoder : NSObject

@property (nonatomic, weak) id<HZVideoToolboxDecoderDelegate> delegate;
- (void)decodeVideoWithVideoInfoData:(HZVideoInfoData)videoInfoData;

@end

NS_ASSUME_NONNULL_END
