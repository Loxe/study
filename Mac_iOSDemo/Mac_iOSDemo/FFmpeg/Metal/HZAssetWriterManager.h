//
//  HZAssetWriterManager.h
//  SmartCamera
//
//  Created by JinTao on 2020/7/30.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>


NS_ASSUME_NONNULL_BEGIN

@interface HZAssetWriterManager : NSObject

@property (nonatomic, assign, getter=isRecording) BOOL recording;

//@property (nonatomic, strong) dispatch_queue_t movieQueue;
@property (nonatomic, strong) NSURL *movieURL;
@property (nonatomic, strong) AVAssetWriter *movieWriter;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *moviePixelBufferAdaptor;
@property (nonatomic, strong) AVAssetWriterInput *movieVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *movieAudioInput;

- (NSURL *)getNewURL;

- (void)startRecordWithVideoSettings:(NSDictionary*)videoSettings
                       audioSettings:(nullable NSDictionary*)audioSettings;
- (void)startRecordWithPixelBuffer:(CVPixelBufferRef)pixelBuffer filePath:(NSString *)filePath;
- (void)recordPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)recordPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime;
- (void)recordSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)stopRecordWithCompletion:(void(^ _Nullable )(BOOL success, NSURL* _Nullable fileURL))completion;

@end

NS_ASSUME_NONNULL_END
