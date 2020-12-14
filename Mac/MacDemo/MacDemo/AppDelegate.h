//
//  AppDelegate.h
//  MacDemo
//
//  Created by JinTao on 2020/12/7.
//

#import <Cocoa/Cocoa.h>
#import "HZXPCProtocol.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSMachPort *port;
@property (nonatomic, strong) id<HZXPCProtocol> remoteObjectProxy;

@end

