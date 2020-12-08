//
//  HZObjectStore.m
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import "HZObjectStore.h"

@interface HZObjectStore ()
@property NSMutableDictionary *objectMap;
@end

@implementation HZObjectStore

// 4-byte selectors to string for easy debugging
+ (NSString *)StringFromPropertySelector:(CMIOObjectPropertySelector)selector {
    switch (selector) {
        case kCMIODevicePropertyPlugIn:
            return @"kCMIODevicePropertyPlugIn";
        case kCMIODevicePropertyDeviceUID:
            return @"kCMIODevicePropertyDeviceUID";
        case kCMIODevicePropertyModelUID:
            return @"kCMIODevicePropertyModelUID";
        case kCMIODevicePropertyTransportType:
            return @"kCMIODevicePropertyTransportType";
        case kCMIODevicePropertyDeviceIsAlive:
            return @"kCMIODevicePropertyDeviceIsAlive";
        case kCMIODevicePropertyDeviceHasChanged:
            return @"kCMIODevicePropertyDeviceHasChanged";
        case kCMIODevicePropertyDeviceIsRunning:
            return @"kCMIODevicePropertyDeviceIsRunning";
        case kCMIODevicePropertyDeviceIsRunningSomewhere:
            return @"kCMIODevicePropertyDeviceIsRunningSomewhere";
        case kCMIODevicePropertyDeviceCanBeDefaultDevice:
            return @"kCMIODevicePropertyDeviceCanBeDefaultDevice";
        case kCMIODevicePropertyHogMode:
            return @"kCMIODevicePropertyHogMode";
        case kCMIODevicePropertyLatency:
            return @"kCMIODevicePropertyLatency";
        case kCMIODevicePropertyStreams:
            return @"kCMIODevicePropertyStreams";
        case kCMIODevicePropertyStreamConfiguration:
            return @"kCMIODevicePropertyStreamConfiguration";
        case kCMIODevicePropertyDeviceMaster:
            return @"kCMIODevicePropertyDeviceMaster";
        case kCMIODevicePropertyExcludeNonDALAccess:
            return @"kCMIODevicePropertyExcludeNonDALAccess";
        case kCMIODevicePropertyClientSyncDiscontinuity:
            return @"kCMIODevicePropertyClientSyncDiscontinuity";
        case kCMIODevicePropertySMPTETimeCallback:
            return @"kCMIODevicePropertySMPTETimeCallback";
        case kCMIODevicePropertyCanProcessAVCCommand:
            return @"kCMIODevicePropertyCanProcessAVCCommand";
        case kCMIODevicePropertyAVCDeviceType:
            return @"kCMIODevicePropertyAVCDeviceType";
        case kCMIODevicePropertyAVCDeviceSignalMode:
            return @"kCMIODevicePropertyAVCDeviceSignalMode";
        case kCMIODevicePropertyCanProcessRS422Command:
            return @"kCMIODevicePropertyCanProcessRS422Command";
        case kCMIODevicePropertyLinkedCoreAudioDeviceUID:
            return @"kCMIODevicePropertyLinkedCoreAudioDeviceUID";
        case kCMIODevicePropertyVideoDigitizerComponents:
            return @"kCMIODevicePropertyVideoDigitizerComponents";
        case kCMIODevicePropertySuspendedByUser:
            return @"kCMIODevicePropertySuspendedByUser";
        case kCMIODevicePropertyLinkedAndSyncedCoreAudioDeviceUID:
            return @"kCMIODevicePropertyLinkedAndSyncedCoreAudioDeviceUID";
        case kCMIODevicePropertyIIDCInitialUnitSpace:
            return @"kCMIODevicePropertyIIDCInitialUnitSpace";
        case kCMIODevicePropertyIIDCCSRData:
            return @"kCMIODevicePropertyIIDCCSRData";
        case kCMIODevicePropertyCanSwitchFrameRatesWithoutFrameDrops:
            return @"kCMIODevicePropertyCanSwitchFrameRatesWithoutFrameDrops";
        case kCMIODevicePropertyLocation:
            return @"kCMIODevicePropertyLocation";
        case kCMIODevicePropertyDeviceHasStreamingError:
            return @"kCMIODevicePropertyDeviceHasStreamingError";
        case kCMIODevicePropertyScopeInput:
            return @"kCMIODevicePropertyScopeInput";
        case kCMIODevicePropertyScopeOutput:
            return @"kCMIODevicePropertyScopeOutput";
        case kCMIODevicePropertyScopePlayThrough:
            return @"kCMIODevicePropertyScopePlayThrough";
        case kCMIOObjectPropertyClass:
            return @"kCMIOObjectPropertyClass";
        case kCMIOObjectPropertyOwner:
            return @"kCMIOObjectPropertyOwner";
        case kCMIOObjectPropertyCreator:
            return @"kCMIOObjectPropertyCreator";
        case kCMIOObjectPropertyName:
            return @"kCMIOObjectPropertyName";
        case kCMIOObjectPropertyManufacturer:
            return @"kCMIOObjectPropertyManufacturer";
        case kCMIOObjectPropertyElementName:
            return @"kCMIOObjectPropertyElementName";
        case kCMIOObjectPropertyElementCategoryName:
            return @"kCMIOObjectPropertyElementCategoryName";
        case kCMIOObjectPropertyElementNumberName:
            return @"kCMIOObjectPropertyElementNumberName";
        case kCMIOObjectPropertyOwnedObjects:
            return @"kCMIOObjectPropertyOwnedObjects";
        case kCMIOObjectPropertyListenerAdded:
            return @"kCMIOObjectPropertyListenerAdded";
        case kCMIOObjectPropertyListenerRemoved:
            return @"kCMIOObjectPropertyListenerRemoved";
        case kCMIOStreamPropertyDirection:
            return @"kCMIOStreamPropertyDirection";
        case kCMIOStreamPropertyTerminalType:
            return @"kCMIOStreamPropertyTerminalType";
        case kCMIOStreamPropertyStartingChannel:
            return @"kCMIOStreamPropertyStartingChannel";
        // Same value as kCMIODevicePropertyLatency
        // case kCMIOStreamPropertyLatency:
        //     return @"kCMIOStreamPropertyLatency";
        case kCMIOStreamPropertyFormatDescription:
            return @"kCMIOStreamPropertyFormatDescription";
        case kCMIOStreamPropertyFormatDescriptions:
            return @"kCMIOStreamPropertyFormatDescriptions";
        case kCMIOStreamPropertyStillImage:
            return @"kCMIOStreamPropertyStillImage";
        case kCMIOStreamPropertyStillImageFormatDescriptions:
            return @"kCMIOStreamPropertyStillImageFormatDescriptions";
        case kCMIOStreamPropertyFrameRate:
            return @"kCMIOStreamPropertyFrameRate";
        case kCMIOStreamPropertyMinimumFrameRate:
            return @"kCMIOStreamPropertyMinimumFrameRate";
        case kCMIOStreamPropertyFrameRates:
            return @"kCMIOStreamPropertyFrameRates";
        case kCMIOStreamPropertyFrameRateRanges:
            return @"kCMIOStreamPropertyFrameRateRanges";
        case kCMIOStreamPropertyNoDataTimeoutInMSec:
            return @"kCMIOStreamPropertyNoDataTimeoutInMSec";
        case kCMIOStreamPropertyDeviceSyncTimeoutInMSec:
            return @"kCMIOStreamPropertyDeviceSyncTimeoutInMSec";
        case kCMIOStreamPropertyNoDataEventCount:
            return @"kCMIOStreamPropertyNoDataEventCount";
        case kCMIOStreamPropertyOutputBufferUnderrunCount:
            return @"kCMIOStreamPropertyOutputBufferUnderrunCount";
        case kCMIOStreamPropertyOutputBufferRepeatCount:
            return @"kCMIOStreamPropertyOutputBufferRepeatCount";
        case kCMIOStreamPropertyOutputBufferQueueSize:
            return @"kCMIOStreamPropertyOutputBufferQueueSize";
        case kCMIOStreamPropertyOutputBuffersRequiredForStartup:
            return @"kCMIOStreamPropertyOutputBuffersRequiredForStartup";
        case kCMIOStreamPropertyOutputBuffersNeededForThrottledPlayback:
            return @"kCMIOStreamPropertyOutputBuffersNeededForThrottledPlayback";
        case kCMIOStreamPropertyFirstOutputPresentationTimeStamp:
            return @"kCMIOStreamPropertyFirstOutputPresentationTimeStamp";
        case kCMIOStreamPropertyEndOfData:
            return @"kCMIOStreamPropertyEndOfData";
        case kCMIOStreamPropertyClock:
            return @"kCMIOStreamPropertyClock";
        case kCMIOStreamPropertyCanProcessDeckCommand:
            return @"kCMIOStreamPropertyCanProcessDeckCommand";
        case kCMIOStreamPropertyDeck:
            return @"kCMIOStreamPropertyDeck";
        case kCMIOStreamPropertyDeckFrameNumber:
            return @"kCMIOStreamPropertyDeckFrameNumber";
        case kCMIOStreamPropertyDeckDropness:
            return @"kCMIOStreamPropertyDeckDropness";
        case kCMIOStreamPropertyDeckThreaded:
            return @"kCMIOStreamPropertyDeckThreaded";
        case kCMIOStreamPropertyDeckLocal:
            return @"kCMIOStreamPropertyDeckLocal";
        case kCMIOStreamPropertyDeckCueing:
            return @"kCMIOStreamPropertyDeckCueing";
        case kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio:
            return @"kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio";
        case kCMIOStreamPropertyScheduledOutputNotificationProc:
            return @"kCMIOStreamPropertyScheduledOutputNotificationProc";
        case kCMIOStreamPropertyPreferredFormatDescription:
            return @"kCMIOStreamPropertyPreferredFormatDescription";
        case kCMIOStreamPropertyPreferredFrameRate:
            return @"kCMIOStreamPropertyPreferredFrameRate";
        case kCMIOControlPropertyScope:
            return @"kCMIOControlPropertyScope";
        case kCMIOControlPropertyElement:
            return @"kCMIOControlPropertyElement";
        case kCMIOControlPropertyVariant:
            return @"kCMIOControlPropertyVariant";
        case kCMIOHardwarePropertyProcessIsMaster:
            return @"kCMIOHardwarePropertyProcessIsMaster";
        case kCMIOHardwarePropertyIsInitingOrExiting:
            return @"kCMIOHardwarePropertyIsInitingOrExiting";
        case kCMIOHardwarePropertyDevices:
            return @"kCMIOHardwarePropertyDevices";
        case kCMIOHardwarePropertyDefaultInputDevice:
            return @"kCMIOHardwarePropertyDefaultInputDevice";
        case kCMIOHardwarePropertyDefaultOutputDevice:
            return @"kCMIOHardwarePropertyDefaultOutputDevice";
        case kCMIOHardwarePropertyDeviceForUID:
            return @"kCMIOHardwarePropertyDeviceForUID";
        case kCMIOHardwarePropertySleepingIsAllowed:
            return @"kCMIOHardwarePropertySleepingIsAllowed";
        case kCMIOHardwarePropertyUnloadingIsAllowed:
            return @"kCMIOHardwarePropertyUnloadingIsAllowed";
        case kCMIOHardwarePropertyPlugInForBundleID:
            return @"kCMIOHardwarePropertyPlugInForBundleID";
        case kCMIOHardwarePropertyUserSessionIsActiveOrHeadless:
            return @"kCMIOHardwarePropertyUserSessionIsActiveOrHeadless";
        case kCMIOHardwarePropertySuspendedBySystem:
            return @"kCMIOHardwarePropertySuspendedBySystem";
        case kCMIOHardwarePropertyAllowScreenCaptureDevices:
            return @"kCMIOHardwarePropertyAllowScreenCaptureDevices";
        case kCMIOHardwarePropertyAllowWirelessScreenCaptureDevices:
            return @"kCMIOHardwarePropertyAllowWirelessScreenCaptureDevices";
        default:
            uint8_t *chars = (uint8_t *)&selector;
            return [NSString stringWithFormat:@"Unknown selector: %c%c%c%c", chars[0], chars[1], chars[2], chars[3]];
        }
}

+ (BOOL)IsBridgedTypeForSelector:(CMIOObjectPropertySelector)selector {
    switch (selector) {
        case kCMIOObjectPropertyName:
        case kCMIOObjectPropertyManufacturer:
        case kCMIOObjectPropertyElementName:
        case kCMIOObjectPropertyElementCategoryName:
        case kCMIOObjectPropertyElementNumberName:
        case kCMIODevicePropertyDeviceUID:
        case kCMIODevicePropertyModelUID:
        case kCMIOStreamPropertyFormatDescriptions:
        case kCMIOStreamPropertyFormatDescription:
        case kCMIOStreamPropertyClock:
            return YES;
        default:
            return NO;
        }
}

+ (HZObjectStore *)SharedObjectStore {
    static HZObjectStore *sObjectStore = nil;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        sObjectStore = [[self alloc] init];
    });
    return sObjectStore;
}

+ (NSObject<HZCMIOObject> *)GetObjectWithId:(CMIOObjectID)objectId {
    return [[HZObjectStore SharedObjectStore] getObject:objectId];
}

- (id)init {
    if (self = [super init]) {
        self.objectMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSObject<HZCMIOObject> *)getObject:(CMIOObjectID)objectID {
    return self.objectMap[@(objectID)];
}

- (void)setObject:(id<HZCMIOObject>)object forObjectId:(CMIOObjectID)objectId {
    self.objectMap[@(objectId)] = object;
}

@end
