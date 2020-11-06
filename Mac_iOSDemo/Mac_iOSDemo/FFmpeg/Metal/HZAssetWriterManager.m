//
//  HZAssetWriterManager.m
//  SmartCamera
//
//  Created by JinTao on 2020/7/30.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "HZAssetWriterManager.h"

/// 这只是用于计算时间戳的帧率, 并不是实际的帧率, 这个值越大, 计算越准确
static const int32_t kHZAssetWriterManagerFrameRate = 600;

@interface HZAssetWriterManager ()

@property (nonatomic, assign, getter=isFirstSample) BOOL firstSample;
@property (nonatomic, assign) int64_t currentFrame;
@property (nonatomic, strong) NSDate *startDate;

@end


@implementation HZAssetWriterManager

- (instancetype)init {
    if (self = [super init]) {
        //self.movieQueue = dispatch_queue_create("com.hz.MovieQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSURL *)getNewURL {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    NSString *directory = [dateString substringToIndex:8];
    NSString *fileName = [dateString substringFromIndex:8];
    NSString *directoryPath = [path stringByAppendingPathComponent:directory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
    NSString *urlPath = [filePath stringByAppendingPathExtension:@"mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:urlPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:urlPath error:nil];
    }
    NSURL *url = [NSURL fileURLWithPath:urlPath];
    return url;
}

- (void)startRecordWithVideoSettings:(NSDictionary *)videoSettings
                       audioSettings:(NSDictionary *)audioSettings {
    self.movieURL = [self getNewURL];
    NSError *error;
    self.movieWriter = [AVAssetWriter assetWriterWithURL:self.movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (!self.movieWriter || error) {
        NSLog(@"movieWriter error. %@", error.userInfo);
        return;
    }
    // 创建视频输入
    self.movieVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    // 针对实时性进行优化
    self.movieVideoInput.expectsMediaDataInRealTime = YES;
    
    NSLog(@"%@", videoSettings);
    NSDictionary *sourcePixelBufferAttributes = @{
        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        (__bridge NSString *)kCVPixelBufferWidthKey : (videoSettings[AVVideoWidthKey] ?: @(0)),
        (__bridge NSString *)kCVPixelBufferHeightKey : (videoSettings[AVVideoHeightKey] ?: @(0)),
        //(__bridge NSString *)kCVPixelFormatOpenGLESCompatibility : @(1),
    };
    self.moviePixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.movieVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    
    if ([self.movieWriter canAddInput:self.movieVideoInput]) {
        [self.movieWriter addInput:self.movieVideoInput];
    } else {
        NSLog(@"Unable to add video input.");
    }
    
    /*// 创建音频输入
     self.movieAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
     // 针对实时性进行优化
     self.movieAudioInput.expectsMediaDataInRealTime = YES;
     if ([self.movieWriter canAddInput:self.movieAudioInput]) {
     [self.movieWriter addInput:self.movieAudioInput];
     } else {
     NSLog(@"Unable to add audio input.");
     }*/
    
    self.recording = YES;
    self.firstSample = YES;
    self.currentFrame = 1;
}

- (void)startRecordWithPixelBuffer:(CVPixelBufferRef)pixelBuffer filePath:(NSString *)filePath {
    NSError *error;
    self.movieURL = [NSURL fileURLWithPath:filePath];
    self.movieWriter = [AVAssetWriter assetWriterWithURL:self.movieURL fileType:AVFileTypeMPEG4 error:&error];
    if (!self.movieWriter || error) {
        NSLog(@"movieWriter error. %@", error.userInfo);
        return;
    }
    size_t w = CVPixelBufferGetWidth(pixelBuffer);
    size_t h = CVPixelBufferGetHeight(pixelBuffer);
    NSDictionary<NSString *, id> *compressionProperties = @{
        AVVideoAverageBitRateKey : @(w * h * 6),
        AVVideoExpectedSourceFrameRateKey : @(15),
        AVVideoMaxKeyFrameIntervalKey : @(15),
        AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel,
    };
    NSDictionary<NSString *, id> *videoCompressionSettings = @{
#if TARGET_OS_MACCATALYST
        AVVideoCodecKey : AVVideoCodecTypeH264,
#else
        AVVideoCodecKey : AVVideoCodecTypeH264,
#endif
        AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
        AVVideoWidthKey : @(w),
        AVVideoHeightKey : @(h),
        AVVideoCompressionPropertiesKey : compressionProperties,
    };
    // 如果 outputSettings 传 nil, 会直接保存pixelBuffer原始数据, 没有压缩
    self.movieVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
    // 针对实时性进行优化
    //self.movieVideoInput.expectsMediaDataInRealTime = YES;
    NSDictionary<NSString *, id> *sourcePixelBufferAttributes = @{
        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        (__bridge NSString *)kCVPixelBufferWidthKey : @(w),
        (__bridge NSString *)kCVPixelBufferHeightKey : @(h),
    };
    self.moviePixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.movieVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    if ([self.movieWriter canAddInput:self.movieVideoInput]) {
        [self.movieWriter addInput:self.movieVideoInput];
    } else {
        NSLog(@"Unable to add video input.");
    }
    
    self.recording = YES;
    self.firstSample = YES;
    self.currentFrame = 0;
    
    self.startDate = [NSDate date];
}

- (void)recordPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) {
        return;
    }
    
    NSDate *date = [NSDate date];
    NSTimeInterval timeInterval = [date timeIntervalSinceDate:self.startDate];
    int64_t currentFrame = timeInterval * kHZAssetWriterManagerFrameRate;
    //NSLog(@"计算的时间戳: %lld", currentFrame);
    if (currentFrame <= self.currentFrame) {
        self.currentFrame++;
    } else {
        self.currentFrame = currentFrame;
    }
    CMTime presentationTime = CMTimeMake(self.currentFrame, kHZAssetWriterManagerFrameRate);
    [self recordPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
}

- (void)recordPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime {
    if (!self.isRecording) {
        return;
    }
    
    if (self.isFirstSample) {
        if ([self.movieWriter startWriting]) {
            [self.movieWriter startSessionAtSourceTime:presentationTime];
        } else {
            NSLog(@"Failed to start writing. %ld %@", (long)self.movieWriter.status, self.movieWriter.error.userInfo);
        }
        self.firstSample = NO;
    }
    if (self.moviePixelBufferAdaptor.assetWriterInput.readyForMoreMediaData) {
        if (![self.moviePixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime]) {
            NSLog(@"Error appending video sample buffer.");
        }
    }
}

- (void)recordSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.isRecording) {
        return;
    }
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    if (mediaType == kCMMediaType_Video) {
        // 视频数据处理
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (self.isFirstSample) {
            if ([self.movieWriter startWriting]) {
                [self.movieWriter startSessionAtSourceTime: timestamp];
            } else {
                NSLog(@"Failed to start writing. %ld %@", (long)self.movieWriter.status, self.movieWriter.error.userInfo);
            }
            self.firstSample = NO;
        }
        if (self.movieVideoInput.readyForMoreMediaData) {
            if (![self.movieVideoInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending video sample buffer.");
            }
        }
    } else if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        // 音频数据处理(已处理至少一个视频数据)
        if (self.movieAudioInput.readyForMoreMediaData) {
            if (![self.movieAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending audio sample buffer.");
            }
        }
    }
}

- (void)stopRecordWithCompletion:(void (^)(BOOL, NSURL * _Nullable))completion {
    self.recording = NO;
    [self.movieVideoInput markAsFinished];
    [self.movieWriter finishWritingWithCompletionHandler:^{
        switch (self.movieWriter.status) {
            case AVAssetWriterStatusCompleted:{
                self.firstSample = YES;
                NSURL *fileURL = [self.movieWriter outputURL];
                if (completion) {
                    completion(YES, fileURL);
                }
                break;
            }
                
            default:
                NSLog(@"Failed to write movie: %@", self.movieWriter.error);
                break;
        }
    }];
}

/// 保存视频
- (void)saveMovieToCameraRoll:(NSURL *)url
                   authHandle:(void (^)(BOOL, PHAuthorizationStatus))authHandle
                   completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if (status != PHAuthorizationStatusAuthorized) {
            authHandle(false, status);
            return;
        }
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCreationRequest *videoRequest = [PHAssetCreationRequest creationRequestForAsset];
            [videoRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:url options:nil];
        } completionHandler:^( BOOL success, NSError * _Nullable error ) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(success, error);
            });
        }];
    }];
}

@end
