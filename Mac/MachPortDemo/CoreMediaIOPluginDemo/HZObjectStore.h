//
//  HZObjectStore.h
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import <CoreMediaIO/CMIOHardwarePlugIn.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HZCMIOObject

- (BOOL)hasPropertyWithAddress:(CMIOObjectPropertyAddress)address;
- (BOOL)isPropertySettableWithAddress:(CMIOObjectPropertyAddress)address;
- (UInt32)getPropertyDataSizeWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(const void*)qualifierData;
- (void)getPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(const void*)qualifierData dataSize:(UInt32)dataSize dataUsed:(UInt32 *)dataUsed data:(void *)data;
- (void)setPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(const void*)qualifierData dataSize:(UInt32)dataSize data:(const void*)data;

@end

@interface HZObjectStore : NSObject

+ (HZObjectStore *)SharedObjectStore;

+ (NSObject<HZCMIOObject> *)GetObjectWithId:(CMIOObjectID)objectId;

+ (NSString *)StringFromPropertySelector:(CMIOObjectPropertySelector)selector;

+ (BOOL)IsBridgedTypeForSelector:(CMIOObjectPropertySelector)selector;

- (NSObject<HZCMIOObject> *)getObject:(CMIOObjectID)objectID;

- (void)setObject:(id<HZCMIOObject>)object forObjectId:(CMIOObjectID)objectId;

@end

NS_ASSUME_NONNULL_END
