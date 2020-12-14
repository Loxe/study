//
//  HZXPCDelegate.h
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/10.
//

#import <Foundation/Foundation.h>
#import "HZXPCProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HZXPCService : NSObject <HZXPCProtocol>

@end


@interface HZXPCDelegate : NSObject<NSXPCListenerDelegate>
+ (instancetype)manager;
@end

NS_ASSUME_NONNULL_END
