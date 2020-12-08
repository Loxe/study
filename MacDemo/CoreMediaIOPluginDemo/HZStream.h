//
//  HZStream.h
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import <Foundation/Foundation.h>

#import "HZObjectStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface HZStream : NSObject <HZCMIOObject>

@property CMIOStreamID objectId;

- (instancetype _Nonnull)init;

- (CMSimpleQueueRef)copyBufferQueueWithAlteredProc:(CMIODeviceStreamQueueAlteredProc)alteredProc alteredRefCon:(void *)alteredRefCon;

- (void)startServingFrames;

- (void)stopServingFrames;

@end

NS_ASSUME_NONNULL_END
