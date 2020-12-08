//
//  HZDevice.h
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import <Foundation/Foundation.h>

#import "HZObjectStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface HZDevice : NSObject <HZCMIOObject>

@property CMIOObjectID objectId;
@property CMIOObjectID pluginId;
@property CMIOObjectID streamId;

@end

NS_ASSUME_NONNULL_END
