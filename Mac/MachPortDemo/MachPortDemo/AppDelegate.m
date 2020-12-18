//
//  AppDelegate.m
//  MachPortDemo
//
//  Created by JinTao on 2020/12/14.
//

#import "AppDelegate.h"
#import "HZXPCDelegate.h"
#import "HZIPCGLobalHeader.h"
#import "HZIPCMachClient.h"
#import "HZIPCGlobalHeader.h"

@protocol HelperProtocol

// Replace the API of this protocol with an API appropriate to the service you are vending.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply;
    
@end

@interface AppDelegate ()

@end

@implementation AppDelegate
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    //[self nsConnectionTest];
    [self XPCTest];
    //[self mach_absolute_time];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - XPC Test
- (void)XPCTest {
    // 这个方法只能用在 XPC 服务中, 且 resume 后, 不会返回, 用在其它地方会报错
    //NSXPCListener *listener = [NSXPCListener serviceListener];
    //[listener resume];
    // 其它地方用下面方法或者 [NSXPCListener anonymousListener]
//    NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.Anywii.MachPortDemo"];
//    listener.delegate = [HZXPCDelegate manager];
//    [listener resume];
    
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.Anywii.HZXPCBundleDemo" options:NSXPCConnectionPrivileged];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)];
    // 获取远程接口调用对象
    id rop = [connection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"出错了: %@", error);
    }];
    [connection resume];
    // 对象调用接口方法
    // 只调前面的方法, 不调这个方法, 服务不会启动
//    [rop test:@"2222" reply:^(NSString *replyString) {
//        NSLog(@"收到了回复: %@", replyString);
//    }];
    [rop upperCaseString:@"233" withReply:^(NSString *s) {
        NSLog(@"reply: %@", s);
    }];
}

#pragma mark - NSConnection Test
- (void)nsConnectionTest {
    //这样就可以通过name取得注册的NSConnection的代理对象
    NSDistantObject *distantObject = [NSConnection rootProxyForConnectionWithRegisteredName:@"com.Anywii.MacDemo" host:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //调用代理对象中的方法，就跟普通对象一样，当然如果为了让代理对象的方法可见，可以定义公共的协议protocol
    [distantObject performSelector:@selector(connectionTest)];
#pragma clang diagnostic pop
}

#pragma mark - Other
- (void)mach_absolute_time {
    HZLog(@"%llu", mach_absolute_time());
}

@end
