//
//  HZXPCDelegate.m
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/10.
//

#import "HZXPCDelegate.h"


@implementation HZXPCService

- (void)test:(NSString *)string reply:(void (^)(NSString *))reply {
    NSLog(@"插件内部收到: %@", string);
    if (reply) {
        reply(@"回复进程通信");
    }
}

@end


@implementation HZXPCDelegate

+ (instancetype)manager {
    static HZXPCDelegate *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HZXPCDelegate alloc] init];
    });
    return instance;
}

#pragma mark - NSXPCListenerDelegate
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    NSLog(@"NSXPCListener 代理方法");
    //设置service端接收消息的配置
    // 每次创建一个新的 NSXPCConnection, 都会调到这里来
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HZXPCProtocol)];
    newConnection.exportedObject = [HZXPCService new];
    [newConnection resume];
    
    return YES;
}

@end
