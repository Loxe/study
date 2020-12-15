//
//  HZPlugInInterface.m
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import "HZPlugInInterface.h"

#import <CoreFoundation/CFUUID.h>

#import "HZPlugIn.h"
#import "HZDevice.h"
#import "HZStream.h"
#import "HZIPCGLobalHeader.h"

#pragma mark Plug-In Operations

static UInt32 sRefCount = 0;

ULONG HardwarePlugIn_AddRef(CMIOHardwarePlugInRef self) {
    sRefCount += 1;
    HZLog(@"sRefCount now = %d", sRefCount);
    return sRefCount;
}

ULONG HardwarePlugIn_Release(CMIOHardwarePlugInRef self) {
    sRefCount -= 1;
    HZLog(@"sRefCount now = %d", sRefCount);
    return sRefCount;
}

HRESULT HardwarePlugIn_QueryInterface(CMIOHardwarePlugInRef self, REFIID uuid, LPVOID* interface) {
    HZLog(@"");
    
    if (!interface) {
        HZLog(@"Received an empty interface");
        return E_POINTER;
    }
    
    // Set the returned interface to NULL in case the UUIDs don't match
    *interface = NULL;
    
    // Create a CoreFoundation UUIDRef for the requested interface.
    CFUUIDRef cfUuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, uuid);
    CFStringRef uuidString = CFUUIDCreateString(NULL, cfUuid);
    CFStringRef hardwarePluginUuid = CFUUIDCreateString(NULL, kCMIOHardwarePlugInInterfaceID);
    
    if (CFEqual(uuidString, hardwarePluginUuid)) {
        // Return the interface;
        sRefCount += 1;
        *interface = PlugInRef();
        return kCMIOHardwareNoError;
    } else {
        HZLog(@"ERR Queried for some weird UUID %@", uuidString);
    }
    
    return E_NOINTERFACE;
}

// I think this is deprecated, seems that HardwarePlugIn_InitializeWithObjectID gets called instead
OSStatus HardwarePlugIn_Initialize(CMIOHardwarePlugInRef self) {
    HZLog(@"ERR self=%p", self);
    return kCMIOHardwareUnspecifiedError;
}

OSStatus HardwarePlugIn_InitializeWithObjectID(CMIOHardwarePlugInRef self, CMIOObjectID objectID) {
    HZLog(@"self=%p", self);
    
    OSStatus error = kCMIOHardwareNoError;
    
    HZPlugIn *plugIn = [HZPlugIn sharedPlugIn];
    plugIn.objectId = objectID;
    [[HZObjectStore sharedObjectStore] setObject:plugIn forObjectId:objectID];
    
    HZDevice *device = [[HZDevice alloc] init];
    CMIOObjectID deviceId;
    error = CMIOObjectCreate(PlugInRef(), kCMIOObjectSystemObject, kCMIODeviceClassID, &deviceId);
    if (error != noErr) {
        HZLog(@"CMIOObjectCreate Error %d", error);
        return error;
    }
    device.objectId = deviceId;
    device.pluginId = objectID;
    [[HZObjectStore sharedObjectStore] setObject:device forObjectId:deviceId];
    
    HZStream *stream = [[HZStream alloc] init];
    CMIOObjectID streamId;
    error = CMIOObjectCreate(PlugInRef(), deviceId, kCMIOStreamClassID, &streamId);
    if (error != noErr) {
        HZLog(@"CMIOObjectCreate Error %d", error);
        return error;
    }
    stream.objectId = streamId;
    [[HZObjectStore sharedObjectStore] setObject:stream forObjectId:streamId];
    device.streamId = streamId;
    plugIn.stream = stream;
    
    // Tell the system about the Device
    error = CMIOObjectsPublishedAndDied(PlugInRef(), kCMIOObjectSystemObject, 1, &deviceId, 0, 0);
    if (error != kCMIOHardwareNoError) {
        HZLog(@"CMIOObjectsPublishedAndDied plugin/device Error %d", error);
        return error;
    }
    
    // Tell the system about the Stream
    error = CMIOObjectsPublishedAndDied(PlugInRef(), deviceId, 1, &streamId, 0, 0);
    if (error != kCMIOHardwareNoError) {
        HZLog(@"CMIOObjectsPublishedAndDied device/stream Error %d", error);
        return error;
    }
    
    return error;
}

OSStatus HardwarePlugIn_Teardown(CMIOHardwarePlugInRef self) {
    HZLog(@"self=%p", self);
    
    OSStatus error = kCMIOHardwareNoError;
    
    HZPlugIn *plugIn = [HZPlugIn sharedPlugIn];
    [plugIn teardown];
    
    return error;
}

#pragma mark CMIOObject Operations

void HardwarePlugIn_ObjectShow(CMIOHardwarePlugInRef self, CMIOObjectID objectID) {
    HZLog(@"self=%p", self);
}

Boolean  HardwarePlugIn_ObjectHasProperty(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address) {
    
    NSObject<HZCMIOObject> *object = [HZObjectStore getObjectWithId:objectID];
    
    if (object == nil) {
        HZLog(@"ERR nil object");
        return false;
    }
    
    Boolean answer = [object hasPropertyWithAddress:*address];
    
    HZLog(@"%@(%d) %@ self=%p hasProperty=%d", NSStringFromClass([object class]), objectID, [HZObjectStore stringFromPropertySelector:address->mSelector], self, answer);
    
    return answer;
}

OSStatus HardwarePlugIn_ObjectIsPropertySettable(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, Boolean* isSettable) {
    
    NSObject<HZCMIOObject> *object = [HZObjectStore getObjectWithId:objectID];
    
    if (object == nil) {
        HZLog(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }
    
    *isSettable = [object isPropertySettableWithAddress:*address];
    
    HZLog(@"%@(%d) %@ self=%p settable=%d", NSStringFromClass([object class]), objectID, [HZObjectStore stringFromPropertySelector:address->mSelector], self, *isSettable);
    
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_ObjectGetPropertyDataSize(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, UInt32 qualifierDataSize, const void* qualifierData, UInt32* dataSize) {
    
    NSObject<HZCMIOObject> *object = [HZObjectStore getObjectWithId:objectID];
    
    if (object == nil) {
        HZLog(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }
    
    *dataSize = [object getPropertyDataSizeWithAddress:*address qualifierDataSize:qualifierDataSize qualifierData:qualifierData];
    
    HZLog(@"%@(%d) %@ self=%p size=%d", NSStringFromClass([object class]), objectID, [HZObjectStore stringFromPropertySelector:address->mSelector], self, *dataSize);
    
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_ObjectGetPropertyData(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, UInt32 qualifierDataSize, const void* qualifierData, UInt32 dataSize, UInt32* dataUsed, void* data) {
    
    NSObject<HZCMIOObject> *object = [HZObjectStore getObjectWithId:objectID];
    
    if (object == nil) {
        HZLog(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }
    
    [object getPropertyDataWithAddress:*address qualifierDataSize:qualifierDataSize qualifierData:qualifierData dataSize:dataSize dataUsed:dataUsed data:data];
    
    if ([HZObjectStore isBridgedTypeForSelector:address->mSelector]) {
        id dataObj = (__bridge NSObject *)*static_cast<CFTypeRef*>(data);
        HZLog(@"%@(%d) %@ self=%p data(id)=%@", NSStringFromClass([object class]), objectID, [HZObjectStore stringFromPropertySelector:address->mSelector], self, dataObj);
    } else {
        UInt32 *dataInt = (UInt32 *)data;
        HZLog(@"%@(%d) %@ self=%p data(int)=%d", NSStringFromClass([object class]), objectID, [HZObjectStore stringFromPropertySelector:address->mSelector], self, *dataInt);
    }
    
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_ObjectSetPropertyData(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, UInt32 qualifierDataSize, const void* qualifierData, UInt32 dataSize, const void* data) {
    
    NSObject<HZCMIOObject> *object = [HZObjectStore getObjectWithId:objectID];
    
    if (object == nil) {
        HZLog(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }
    
    UInt32 *dataInt = (UInt32 *)data;
    HZLog(@"%@(%d) %@ self=%p data(int)=%d", NSStringFromClass([object class]), objectID, [HZObjectStore stringFromPropertySelector:address->mSelector], self, *dataInt);
    
    [object setPropertyDataWithAddress:*address qualifierDataSize:qualifierDataSize qualifierData:qualifierData dataSize:dataSize data:data];
    
    return kCMIOHardwareNoError;
}

#pragma mark CMIOStream Operations
OSStatus HardwarePlugIn_StreamCopyBufferQueue(CMIOHardwarePlugInRef self, CMIOStreamID streamID, CMIODeviceStreamQueueAlteredProc queueAlteredProc, void* queueAlteredRefCon, CMSimpleQueueRef* queue) {
    
    HZStream *stream = (HZStream *)[HZObjectStore getObjectWithId:streamID];
    
    if (stream == nil) {
        HZLog(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }
    
    *queue = [stream copyBufferQueueWithAlteredProc:queueAlteredProc alteredRefCon:queueAlteredRefCon];
    
    HZLog(@"%@ (id=%d) self=%p queue=%@", stream, streamID, self, (__bridge NSObject *)*queue);
    
    return kCMIOHardwareNoError;
}

#pragma mark CMIODevice Operations
OSStatus HardwarePlugIn_DeviceStartStream(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIOStreamID streamID) {
    HZLog(@"self=%p device=%d stream=%d", self, deviceID, streamID);
    
    HZStream *stream = (HZStream *)[HZObjectStore getObjectWithId:streamID];
    
    if (stream == nil) {
        HZLog(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }
    
    [[HZPlugIn sharedPlugIn] startStream];
    
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceSuspend(CMIOHardwarePlugInRef self, CMIODeviceID deviceID) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceResume(CMIOHardwarePlugInRef self, CMIODeviceID deviceID) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceStopStream(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIOStreamID streamID) {
    HZLog(@"self=%p device=%d stream=%d", self, deviceID, streamID);
    
    HZStream *stream = (HZStream *)[HZObjectStore getObjectWithId:streamID];
    
    if (stream == nil) {
        HZLog(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }
    
    [[HZPlugIn sharedPlugIn] stopStream];
    
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceProcessAVCCommand(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIODeviceAVCCommand* ioAVCCommand) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceProcessRS422Command(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIODeviceRS422Command* ioRS422Command) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_StreamDeckPlay(CMIOHardwarePlugInRef self, CMIOStreamID streamID) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

OSStatus HardwarePlugIn_StreamDeckStop(CMIOHardwarePlugInRef self,CMIOStreamID streamID) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

OSStatus HardwarePlugIn_StreamDeckJog(CMIOHardwarePlugInRef self, CMIOStreamID streamID, SInt32 speed) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

OSStatus HardwarePlugIn_StreamDeckCueTo(CMIOHardwarePlugInRef self, CMIOStreamID streamID, Float64 requestedTimecode, Boolean playOnCue) {
    HZLog(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

static CMIOHardwarePlugInInterface sInterface = {
    // Padding for COM
    NULL,
    
    // 函数里面没有内容, 就没调用过
    // IUnknown Routines
    (HRESULT (*)(void*, CFUUIDBytes, void**))HardwarePlugIn_QueryInterface,
    (ULONG (*)(void*))HardwarePlugIn_AddRef,
    (ULONG (*)(void*))HardwarePlugIn_Release,
    
    // DAL Plug-In Routines
    HardwarePlugIn_Initialize,
    HardwarePlugIn_InitializeWithObjectID,
    HardwarePlugIn_Teardown,
    HardwarePlugIn_ObjectShow,
    HardwarePlugIn_ObjectHasProperty,
    HardwarePlugIn_ObjectIsPropertySettable,
    HardwarePlugIn_ObjectGetPropertyDataSize,
    HardwarePlugIn_ObjectGetPropertyData,
    HardwarePlugIn_ObjectSetPropertyData,
    HardwarePlugIn_DeviceSuspend,
    HardwarePlugIn_DeviceResume,
    HardwarePlugIn_DeviceStartStream,
    HardwarePlugIn_DeviceStopStream,
    HardwarePlugIn_DeviceProcessAVCCommand,
    HardwarePlugIn_DeviceProcessRS422Command,
    HardwarePlugIn_StreamCopyBufferQueue,
    HardwarePlugIn_StreamDeckPlay,
    HardwarePlugIn_StreamDeckStop,
    HardwarePlugIn_StreamDeckJog,
    HardwarePlugIn_StreamDeckCueTo
};

static CMIOHardwarePlugInInterface* sInterfacePtr = &sInterface;
static CMIOHardwarePlugInRef sPlugInRef = &sInterfacePtr;

CMIOHardwarePlugInRef PlugInRef() {
    return sPlugInRef;
    xpc_object_t xobj;
    IOSurfaceLookupFromXPCObject(xobj);
    IOSurfaceCreateMachPort(<#IOSurfaceRef  _Nonnull buffer#>)
}
