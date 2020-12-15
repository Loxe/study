//
//  HZStream.m
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import "HZStream.h"

#import <AppKit/AppKit.h>
#import <mach/mach_time.h>
#include <CoreMediaIO/CMIOSampleBuffer.h>

#import "HZIPCGLobalHeader.h"

@interface HZStream ()

@property (nonatomic, strong) dispatch_source_t promptSource;
@property (nonatomic, assign) CMIODeviceStreamQueueAlteredProc alteredProc;
@property (nonatomic, assign) void * alteredRefCon;
@property (nonatomic, assign) CMSimpleQueueRef queue;
@property (nonatomic, assign) CFTypeRef clock;
@property (nonatomic, assign) UInt64 sequenceNumber;

@property (nonatomic, assign) CVPixelBufferRef promptPixelBuffer;
@property (nonatomic, assign) int64_t waitPromptTime;

@end

@implementation HZStream

#define FPS 30.0

- (instancetype _Nonnull)init {
    self = [super init];
    if (self) {
        self.waitPromptTime = 2;
        
        self.promptSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, self.waitPromptTime * NSEC_PER_SEC);
        uint64_t intervalTime = (int64_t)(self.waitPromptTime * NSEC_PER_SEC);
        dispatch_source_set_timer(self.promptSource, startTime, intervalTime, 0);
        __weak typeof(self) wself = self;
        dispatch_source_set_event_handler(self.promptSource, ^{
            [wself showPromptFrame];
        });
        dispatch_resume(self.promptSource);
    }
    return self;
}

- (void)dealloc {
    HZLog(@"Stream Dealloc");
    CMIOStreamClockInvalidate(self.clock);
    CFRelease(self.clock);
    self.clock = NULL;
    CFRelease(self.queue);
    self.queue = NULL;
    dispatch_suspend(self.promptSource);
    CVPixelBufferRelease(self.promptPixelBuffer);
    self.promptPixelBuffer = NULL;
}

- (CMSimpleQueueRef)queue {
    if (_queue == NULL) {
        // Allocate a one-second long queue, which we can use our FPS constant for.
        OSStatus err = CMSimpleQueueCreate(kCFAllocatorDefault, FPS, &_queue);
        if (err != noErr) {
            HZLog(@"Err %d in CMSimpleQueueCreate", err);
        }
    }
    return _queue;
}

- (CFTypeRef)clock {
    if (_clock == NULL) {
        OSStatus err = CMIOStreamClockCreate(kCFAllocatorDefault, CFSTR("CMIOMinimalSample::Stream::clock"), (__bridge void *)self,  CMTimeMake(1, 10), 100, 10, &_clock);
        if (err != noErr) {
            HZLog(@"Error %d from CMIOStreamClockCreate", err);
        }
    }
    return _clock;
}

#pragma mark - PromptFrame
- (CVPixelBufferRef)createPromptPixelBufferWithWidth:(size_t)width height:(size_t)height {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, width, height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, kCGImageAlphaPremultipliedFirst | kCGImageByteOrder32Big);
    NSParameterAssert(context);
    
    //反转
    CGContextTranslateCTM(context, width, 0);
    CGContextScaleCTM(context, -1.0, 1.0);
    
    // 黑底
    CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    
    CGContextSetFillColorWithColor(context, blackColor);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    
    CFRelease(blackColor);
    
    // 文字
    static int a = 0;
    NSString *s  = [NSString stringWithFormat:@"请插入UVC摄像头 %d", a++];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:s attributes:@{
        NSFontAttributeName : [NSFont systemFontOfSize:36.0f],
        NSForegroundColorAttributeName : [NSColor whiteColor],
    }];
    NSRect bound = [string boundingRectWithSize:NSMakeSize(width, height) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect rect = CGRectMake((width - bound.size.width) / 2, -(height - bound.size.height) / 2, width, height);
    CGPathAddRect(path, NULL, rect);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, string.length), path, NULL);
    CTFrameDraw(frame, context);
    CFRelease(framesetter);
    CFRelease(frame);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)showPromptFrame {
#pragma todo 这里后面要改
    //if (!self.promptPixelBuffer) {
        self.promptPixelBuffer = [self createPromptPixelBufferWithWidth:1280 height:720];
    //}
    [self showPixelBuff:self.promptPixelBuffer];
}

- (void)showPixelBuff:(CVPixelBufferRef)pixelBuffer {
    if (CMSimpleQueueGetFullness(self.queue) >= 1.0) {
        HZLog(@"Queue is full, bailing out");
        return;
    }
    CMTime time = CMTimeMake(mach_absolute_time(), 1);
    CMSampleTimingInfo timing;
    timing.duration = CMTimeMake(1, 1);
    timing.presentationTimeStamp = time;
    timing.decodeTimeStamp = time;
    OSStatus err = CMIOStreamClockPostTimingEvent(time, mach_absolute_time(), true, self.clock);
    if (err != noErr) {
        HZLog(@"CMIOStreamClockPostTimingEvent err %d", err);
    }
    
    CMFormatDescriptionRef format;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &format);
    
    self.sequenceNumber = CMIOGetNextSequenceNumber(self.sequenceNumber);
    
    CMSampleBufferRef buffer;
    err = CMIOSampleBufferCreateForImageBuffer(
                                               kCFAllocatorDefault,
                                               pixelBuffer,
                                               format,
                                               &timing,
                                               self.sequenceNumber,
                                               kCMIOSampleBufferNoDiscontinuities,
                                               &buffer
                                               );
    CFRelease(format);
    if (err != noErr) {
        HZLog(@"CMIOSampleBufferCreateForImageBuffer err %d", err);
    }
    
    CMSimpleQueueEnqueue(self.queue, buffer);
    
    // Inform the clients that the queue has been altered
    if (self.alteredProc != NULL) {
        (self.alteredProc)(self.objectId, buffer, self.alteredRefCon);
    }
}

- (CMVideoFormatDescriptionRef)getFormatDescription {
    CMVideoFormatDescriptionRef formatDescription;
    OSStatus err = CMVideoFormatDescriptionCreate(kCFAllocatorDefault, kCMVideoCodecType_422YpCbCr8, 1280, 720, NULL, &formatDescription);
    if (err != noErr) {
        HZLog(@"Error %d from CMVideoFormatDescriptionCreate", err);
    }
    return formatDescription;
}

#pragma mark - External data
- (void)showFrameData:(NSData *)frameData withWidth:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow {
    void *baseAddress = malloc(frameData.length);
    memcpy(baseAddress, frameData.bytes, frameData.length);
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn ret = CVPixelBufferCreateWithBytes(NULL, width, height, kCVPixelFormatType_32ARGB, baseAddress, bytesPerRow, NULL, NULL, NULL, &pixelBuffer);
    if (ret == kCVReturnSuccess) {
        NSLog(@"创建 CVPixelBufferRef 成功");
    } else {
        NSLog(@"创建 CVPixelBufferRef 失败: %d", ret);
        free(baseAddress);
        return;
    }
    
    [self showPixelBuff:pixelBuffer];
    
    CVPixelBufferRelease(pixelBuffer);
    free(baseAddress);
    
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, self.waitPromptTime * NSEC_PER_SEC);
    uint64_t intervalTime = (int64_t)(self.waitPromptTime * NSEC_PER_SEC);
    dispatch_source_set_timer(self.promptSource, startTime, intervalTime, 0);
}

#pragma mark - BufferQueue
- (CMSimpleQueueRef)copyBufferQueueWithAlteredProc:(CMIODeviceStreamQueueAlteredProc)alteredProc alteredRefCon:(void *)alteredRefCon {
    self.alteredProc = alteredProc;
    self.alteredRefCon = alteredRefCon;
    
    // Retain this since it's a copy operation
    CFRetain(self.queue);
    
    return self.queue;
}

#pragma mark - CMIOObject
- (UInt32)getPropertyDataSizeWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData {
    switch (address.mSelector) {
        case kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio:
            return sizeof(CMTime);
        case kCMIOStreamPropertyOutputBuffersNeededForThrottledPlayback:
            return sizeof(UInt32);
        case kCMIOObjectPropertyName:
            return sizeof(CFStringRef);
        case kCMIOObjectPropertyManufacturer:
            return sizeof(CFStringRef);
        case kCMIOObjectPropertyElementName:
            return sizeof(CFStringRef);
        case kCMIOObjectPropertyElementCategoryName:
            return sizeof(CFStringRef);
        case kCMIOObjectPropertyElementNumberName:
            return sizeof(CFStringRef);
        case kCMIOStreamPropertyDirection:
            return sizeof(UInt32);
        case kCMIOStreamPropertyTerminalType:
            return sizeof(UInt32);
        case kCMIOStreamPropertyStartingChannel:
            return sizeof(UInt32);
        case kCMIOStreamPropertyLatency:
            return sizeof(UInt32);
        case kCMIOStreamPropertyFormatDescriptions:
            return sizeof(CFArrayRef);
        case kCMIOStreamPropertyFormatDescription:
            return sizeof(CMFormatDescriptionRef);
        case kCMIOStreamPropertyFrameRateRanges:
            return sizeof(AudioValueRange);
        case kCMIOStreamPropertyFrameRate:
        case kCMIOStreamPropertyFrameRates:
            return sizeof(Float64);
        case kCMIOStreamPropertyMinimumFrameRate:
            return sizeof(Float64);
        case kCMIOStreamPropertyClock:
            return sizeof(CFTypeRef);
        default:
            HZLog(@"Stream unhandled getPropertyDataSizeWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            return 0;
    };
}

- (void)getPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData dataSize:(UInt32)dataSize dataUsed:(nonnull UInt32 *)dataUsed data:(nonnull void *)data {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            *static_cast<CFStringRef*>(data) = CFSTR("CMIOMinimalSample Stream");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIOObjectPropertyElementName:
            *static_cast<CFStringRef*>(data) = CFSTR("CMIOMinimalSample Stream Element");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIOObjectPropertyManufacturer:
        case kCMIOObjectPropertyElementCategoryName:
        case kCMIOObjectPropertyElementNumberName:
        case kCMIOStreamPropertyTerminalType:
        case kCMIOStreamPropertyStartingChannel:
        case kCMIOStreamPropertyLatency:
        case kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio:
        case kCMIOStreamPropertyOutputBuffersNeededForThrottledPlayback:
            HZLog(@"TODO: %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            break;
        case kCMIOStreamPropertyDirection:
            *static_cast<UInt32*>(data) = 1;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIOStreamPropertyFormatDescriptions:
            HZLog(@"kCMIOStreamPropertyFormatDescriptions");
            *static_cast<CFArrayRef*>(data) = (__bridge_retained CFArrayRef)[NSArray arrayWithObject:(__bridge_transfer NSObject *)[self getFormatDescription]];
            *dataUsed = sizeof(CFArrayRef);
            break;
        case kCMIOStreamPropertyFormatDescription:
            HZLog(@"kCMIOStreamPropertyFormatDescription");
            *static_cast<CMVideoFormatDescriptionRef*>(data) = [self getFormatDescription];
            *dataUsed = sizeof(CMVideoFormatDescriptionRef);
            break;
        case kCMIOStreamPropertyFrameRateRanges:
            AudioValueRange range;
            range.mMinimum = FPS;
            range.mMaximum = FPS;
            *static_cast<AudioValueRange*>(data) = range;
            *dataUsed = sizeof(AudioValueRange);
            break;
        case kCMIOStreamPropertyFrameRate:
        case kCMIOStreamPropertyFrameRates:
            *static_cast<Float64*>(data) = FPS;
            *dataUsed = sizeof(Float64);
            break;
        case kCMIOStreamPropertyMinimumFrameRate:
            *static_cast<Float64*>(data) = FPS;
            *dataUsed = sizeof(Float64);
            break;
        case kCMIOStreamPropertyClock:
            *static_cast<CFTypeRef*>(data) = self.clock;
            // This one was incredibly tricky and cost me many hours to find. It seems that DAL expects
            // the clock to be retained when returned. It's unclear why, and that seems inconsistent
            // with other properties that don't have the same behavior. But this is what Apple's sample
            // code does.
            // https://github.com/lvsti/CoreMediaIO-DAL-Example/blob/0392cb/Sources/Extras/CoreMediaIO/DeviceAbstractionLayer/Devices/DP/Properties/CMIO_DP_Property_Clock.cpp#L75
            CFRetain(*static_cast<CFTypeRef*>(data));
            *dataUsed = sizeof(CFTypeRef);
            break;
        default:
            HZLog(@"Stream unhandled getPropertyDataWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            *dataUsed = 0;
    };
}

- (BOOL)hasPropertyWithAddress:(CMIOObjectPropertyAddress)address {
    switch (address.mSelector){
        case kCMIOObjectPropertyName:
        case kCMIOObjectPropertyElementName:
        case kCMIOStreamPropertyFormatDescriptions:
        case kCMIOStreamPropertyFormatDescription:
        case kCMIOStreamPropertyFrameRateRanges:
        case kCMIOStreamPropertyFrameRate:
        case kCMIOStreamPropertyFrameRates:
        case kCMIOStreamPropertyMinimumFrameRate:
        case kCMIOStreamPropertyClock:
            return true;
        case kCMIOObjectPropertyManufacturer:
        case kCMIOObjectPropertyElementCategoryName:
        case kCMIOObjectPropertyElementNumberName:
        case kCMIOStreamPropertyDirection:
        case kCMIOStreamPropertyTerminalType:
        case kCMIOStreamPropertyStartingChannel:
        case kCMIOStreamPropertyLatency:
        case kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio:
        case kCMIOStreamPropertyOutputBuffersNeededForThrottledPlayback:
            HZLog(@"TODO: %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            return false;
        default:
            HZLog(@"Stream unhandled hasPropertyWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            return false;
    };
}

- (BOOL)isPropertySettableWithAddress:(CMIOObjectPropertyAddress)address {
    HZLog(@"Stream unhandled isPropertySettableWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
    return false;
}

- (void)setPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData dataSize:(UInt32)dataSize data:(nonnull const void *)data {
    HZLog(@"Stream unhandled setPropertyDataWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
}

@end
