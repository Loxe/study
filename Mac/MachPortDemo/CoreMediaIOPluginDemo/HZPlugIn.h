//
//  HZPlugIn.h
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import <CoreMediaIO/CMIOHardwarePlugIn.h>

#import "HZObjectStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface HZPlugIn : NSObject <HZCMIOObject>

@property CMIOObjectID objectId;

+ (HZPlugIn *)SharedPlugIn;

- (void)initialize;

- (void)teardown;

@end

NS_ASSUME_NONNULL_END
