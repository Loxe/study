//
//  HZPlugIn.h
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import <CoreMediaIO/CMIOHardwarePlugIn.h>

#import "HZObjectStore.h"
#import "HZStream.h"

NS_ASSUME_NONNULL_BEGIN

@interface HZPlugIn : NSObject <HZCMIOObject>

@property (nonatomic, assign) CMIOObjectID objectId;
@property (nonatomic, strong) HZStream *stream;

+ (HZPlugIn *)sharedPlugIn;
- (void)initialize;
- (void)teardown;
- (void)startStream;
- (void)stopStream;

@end

NS_ASSUME_NONNULL_END
