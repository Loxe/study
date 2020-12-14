//
//  HZIPCMachClient.h
//  MachPortDemo
//
//  Created by JinTao on 2020/12/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HZIPCMachClientDelegate <NSObject>

@optional
- (void)receivedFrameWithSize:(NSSize)size timestamp:(uint64_t)timestamp fpsNumerator:(uint32_t)fpsNumerator fpsDenominator:(uint32_t)fpsDenominator frameData:(NSData *)frameData;
- (void)receivedFrameData:(NSData *)frameData withWidth:(size_t)width height:(size_t)height;
- (void)receivedStop;

@end


@interface HZIPCMachClient : NSObject

@property (nullable, weak, nonatomic) id<HZIPCMachClientDelegate> delegate;

- (BOOL)isServerAvailable;

- (BOOL)connectToServer;

@end

NS_ASSUME_NONNULL_END
