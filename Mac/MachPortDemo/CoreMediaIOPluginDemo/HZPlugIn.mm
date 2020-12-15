//
//  HZPlugIn.m
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import "HZPlugIn.h"

#import <CoreMediaIO/CMIOHardwarePlugIn.h>
#import "HZIPCGLobalHeader.h"
#import "HZIPCMachClient.h"


typedef NS_ENUM(NSUInteger, HZPlugInState) {
    HZPlugInStateNotStarted = 0,
    HZPlugInStateWaitingForServer,
    HZPlugInStateReceivingFrames,
};

@interface HZPlugIn () <HZIPCMachClientDelegate>
@property (nonatomic, strong) dispatch_queue_t stateQueue;
@property (nonatomic, strong) dispatch_source_t machConnectTimer;
@property (nonatomic, strong) dispatch_source_t timeoutTimer;
@property (nonatomic, assign) HZPlugInState state;
@property (nonatomic, strong) HZIPCMachClient *machClient;
@end


@implementation HZPlugIn

+ (HZPlugIn *)sharedPlugIn {
    static HZPlugIn *sPlugIn = nil;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        sPlugIn = [[self alloc] init];
    });
    /*
    @synchronized (self) {
        if (!sPlugIn) {
            sPlugIn = [[[self class] alloc] init];
        }
    }*/
    return sPlugIn;
}

- (instancetype)init {
    if (self = [super init]) {
        
        self.machClient = [[HZIPCMachClient alloc] init];
        self.machClient.delegate = self;
        
        self.stateQueue = dispatch_queue_create("HZCoreMediaIOPlugInQueue", DISPATCH_QUEUE_SERIAL);
        
        self.timeoutTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.stateQueue);
        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.timeoutTimer, ^{
            if (weakSelf.state == HZPlugInStateReceivingFrames) {
                HZLog(@"No frames received for 5s, restarting connection");
                [weakSelf stopStream];
                [weakSelf startStream];
            }
        });

        self.machConnectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.stateQueue);
        dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 0);
        uint64_t intervalTime = (int64_t)(1 * NSEC_PER_SEC);
        dispatch_source_set_timer(self.machConnectTimer, startTime, intervalTime, 0);
        dispatch_source_set_event_handler(self.machConnectTimer, ^{
            if (![weakSelf.machClient isServerAvailable]) {
                HZLog(@"Server is not available");
            } else if (weakSelf.state == HZPlugInStateWaitingForServer) {
                HZLog(@"Attempting connection");
                [weakSelf.machClient connectToServer];
            }
        });
    }
    return self;
}

- (void)startStream {
    HZLog(@"");
    dispatch_async(self.stateQueue, ^{
        if (self.state == HZPlugInStateNotStarted) {
            dispatch_resume(self.machConnectTimer);
            self.state = HZPlugInStateWaitingForServer;
        }
    });
}

- (void)stopStream {
    HZLog(@"");
    dispatch_async(self.stateQueue, ^{
        if (self.state == HZPlugInStateWaitingForServer) {
            dispatch_suspend(self.machConnectTimer);
        } else if (self.state == HZPlugInStateReceivingFrames) {
            dispatch_suspend(self.timeoutTimer);
            
            [self.machClient disconnectToServer];
        }
        self.state = HZPlugInStateNotStarted;
    });
}

- (void)initialize {
    
}

- (void)teardown {
    
}

#pragma mark - CMIOObject
- (BOOL)hasPropertyWithAddress:(CMIOObjectPropertyAddress)address {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            return true;
        default:
            HZLog(@"PlugIn unhandled hasPropertyWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            return false;
    };
}

- (BOOL)isPropertySettableWithAddress:(CMIOObjectPropertyAddress)address {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            return false;
        default:
            HZLog(@"PlugIn unhandled isPropertySettableWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            return false;
    };
}

- (UInt32)getPropertyDataSizeWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(const void*)qualifierData {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            return sizeof(CFStringRef);
        default:
            HZLog(@"PlugIn unhandled getPropertyDataSizeWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            return 0;
    };
}

- (void)getPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData dataSize:(UInt32)dataSize dataUsed:(nonnull UInt32 *)dataUsed data:(nonnull void *)data {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            *static_cast<CFStringRef*>(data) = CFSTR("CMIOMinimalSample Plugin");
            *dataUsed = sizeof(CFStringRef);
            return;
        default:
            HZLog(@"PlugIn unhandled getPropertyDataWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
            return;
        };
}

- (void)setPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData dataSize:(UInt32)dataSize data:(nonnull const void *)data {
    HZLog(@"PlugIn unhandled setPropertyDataWithAddress for %@", [HZObjectStore stringFromPropertySelector:address.mSelector]);
}

#pragma mark - HZIPCMachClientDelegate
- (void)receivedFrameData:(NSData *)frameData withWidth:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow {
    dispatch_sync(self.stateQueue, ^{
        if (self.state == HZPlugInStateWaitingForServer) {
            /*NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:size.width forKey:kTestCardWidthKey];
            [defaults setInteger:size.height forKey:kTestCardHeightKey];
            double fps = (double)fpsNumerator/(double)fpsDenominator;
            [defaults setDouble:fps forKey:kTestCardFPSKey];
            DLog(@"Saving frame info %dx%d fps=%d/%d=%f", size.width, size.height, fpsNumerator, fpsDenominator, fps);
            */
            
            dispatch_suspend(self.machConnectTimer);
            dispatch_resume(self.timeoutTimer);
            self.state = HZPlugInStateReceivingFrames;
        }
    });

    // Add 5 more seconds onto the timeout timer
    dispatch_source_set_timer(self.timeoutTimer, dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), 5.0 * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
    
    //[self.stream queueFrameWithSize:size timestamp:timestamp fpsNumerator:fpsNumerator fpsDenominator:fpsDenominator frameData:frameData];
}

- (void)receivedStop {
    HZLog(@"Restarting connection");
    [self stopStream];
    [self startStream];
    
    [self.stream showPromptFrame];
}

@end
