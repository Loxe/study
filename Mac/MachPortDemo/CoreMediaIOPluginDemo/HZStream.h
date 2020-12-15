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

- (CMSimpleQueueRef)copyBufferQueueWithAlteredProc:(CMIODeviceStreamQueueAlteredProc)alteredProc alteredRefCon:(void *)alteredRefCon;

- (void)showPromptFrame;
- (void)showFrameData:(NSData *)frameData withWidth:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow;

@end

NS_ASSUME_NONNULL_END
