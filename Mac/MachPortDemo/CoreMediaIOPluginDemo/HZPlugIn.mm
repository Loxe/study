//
//  HZPlugIn.m
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import "HZPlugIn.h"

#import <CoreMediaIO/CMIOHardwarePlugIn.h>

#import "HZLogging.h"

#import "HZXPCDelegate.h"

@implementation HZPlugIn

+ (HZPlugIn *)SharedPlugIn {
    static HZPlugIn *sPlugIn = nil;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        sPlugIn = [[self alloc] init];
        // 这个方法只能用在 XPC 服务中, 具 resume 后, 不会返回, 用在其它地方会报错
        //NSXPCListener *listener = [NSXPCListener serviceListener];
        //[listener resume];
        // 其它地方用下面方法或者 [NSXPCListener anonymousListener]
        NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.Anywii.CoreMediaIOPluginDemo"];
        listener.delegate = [HZXPCDelegate manager];
        [listener resume];
    });
    return sPlugIn;
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
            DLog(@"PlugIn unhandled hasPropertyWithAddress for %@", [HZObjectStore StringFromPropertySelector:address.mSelector]);
            return false;
    };
}

- (BOOL)isPropertySettableWithAddress:(CMIOObjectPropertyAddress)address {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            return false;
        default:
            DLog(@"PlugIn unhandled isPropertySettableWithAddress for %@", [HZObjectStore StringFromPropertySelector:address.mSelector]);
            return false;
    };
}

- (UInt32)getPropertyDataSizeWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(const void*)qualifierData {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            return sizeof(CFStringRef);
        default:
            DLog(@"PlugIn unhandled getPropertyDataSizeWithAddress for %@", [HZObjectStore StringFromPropertySelector:address.mSelector]);
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
            DLog(@"PlugIn unhandled getPropertyDataWithAddress for %@", [HZObjectStore StringFromPropertySelector:address.mSelector]);
            return;
        };
}

- (void)setPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData dataSize:(UInt32)dataSize data:(nonnull const void *)data {
    DLog(@"PlugIn unhandled setPropertyDataWithAddress for %@", [HZObjectStore StringFromPropertySelector:address.mSelector]);
}

@end
