//
//  HZRecorder.m
//  Glimpse
//
//  Created by JinTao on 2020/7/1.
//  Copyright © 2020 Wess Cope. All rights reserved.
//

#import "HZRecorder.h"
#import <AVFoundation/AVFoundation.h>

@implementation UIView (CVPixelBuffer)

- (CVPixelBufferRef)CVPixelBufferRef {
     
    CGSize size = self.frame.size;
    NSDictionary *options = @{(NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]};
    CVPixelBufferRef pxbuffer = NULL;
     
    CGFloat frameWidth = size.width;
    CGFloat frameHeight = size.height;
     
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
     
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
     
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
     
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
     
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, kCGImageAlphaPremultipliedFirst);
     
    NSParameterAssert(context);
     
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, frameHeight);
    CGContextConcatCTM(context, flipVertical);
    
    //CGAffineTransform flipHorizontal = CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, frameWidth, 0.0 );
    //CGContextConcatCTM(context, flipHorizontal);
    
    [self.layer renderInContext:context];
//    UIGraphicsPushContext(context);
//    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
//    UIGraphicsPopContext();
     
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
     
    return pxbuffer;
}

@end


@interface HZRecorder()

@property (strong, nonatomic) UIView *sourceView;

@property (assign, nonatomic) NSInteger framesPerSecond;
@property (assign, nonatomic) NSUInteger timeCount;

@property (strong, nonatomic) AVAssetWriter                         *writer;
@property (strong, nonatomic) AVAssetWriterInput                    *input;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor  *adapter;

@property (strong, nonatomic) CADisplayLink *displayLink;

@end


@implementation HZRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)startRecordingView:(UIView *)view outputURL:(NSURL *)outputURL {
    self.sourceView = view;
    CGSize size = view.bounds.size;
    self.framesPerSecond = 30.0;
    
    NSError *error = nil;
    self.writer = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeMPEG4 error:&error];
    NSAssert(error == nil, error.debugDescription);
    
#if TARGET_OS_MACCATALYST
    AVVideoCodecType type = AVVideoCodecTypeH264;
#else
    AVVideoCodecType type = AVVideoCodecH264;
#endif
    NSDictionary *settings = @{
        AVVideoCodecKey: type,
        AVVideoWidthKey: @(size.width),
        AVVideoHeightKey: @(size.height)
    };
    
    self.input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    self.input.expectsMediaDataInRealTime = YES;
    
    NSDictionary *attributes = @{
                                 (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
                                 (NSString *)kCVPixelBufferWidthKey: @(size.width),
                                 (NSString *)kCVPixelBufferHeightKey: @(size.height)
                                 };
    self.adapter = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.input sourcePixelBufferAttributes:attributes];
    
    [self.writer addInput:self.input];
    [self.writer startWriting];
    [self.writer startSessionAtSourceTime:kCMTimeZero];
    
    self.timeCount = 0;
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(recordAction)];
    self.displayLink.preferredFramesPerSecond = self.framesPerSecond;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)recordAction {
    //获取像素数据
    CVPixelBufferRef buffer = [self.sourceView CVPixelBufferRef];
    //写入像素数据
    dispatch_queue_global_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        if (!self.input.readyForMoreMediaData) {
            NSLog(@"readyForMoreMediaData 未准备");
            return;
        }
        
        CMTime present = CMTimeMake(self.timeCount , (int32_t)self.framesPerSecond);
        BOOL success = [self.adapter appendPixelBuffer:buffer withPresentationTime:present];
        if(!success) {
            NSLog(@"Failed to write image: %@", [self.writer error].userInfo);
        } else {
            NSLog(@"write image %lu", (unsigned long)self.timeCount);
        }
        
        if(buffer) {
            CVBufferRelease(buffer);
        }
        self.timeCount++;
    });
}

- (void)stop {
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    [self.input markAsFinished];
    [self.writer finishWritingWithCompletionHandler:^{
        NSLog(@"录完了");
    }];
}

@end
