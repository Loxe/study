//
//  main.m
//  XPCService
//
//  Created by JinTao on 2020/12/10.
//

#import <Foundation/Foundation.h>
#import "HZXPCDelegate.h"


int main(int argc, const char *argv[])
{
    // 多次创建 NSXPCConnection, 此 main 函数只会调用一次
    NSLog(@"服务启动");
    
    // Create the delegate for the service.
    HZXPCDelegate *delegate = [HZXPCDelegate manager];
    
    // Set up the one NSXPCListener for this service. It will handle all incoming connections.
    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;
    
    // Resuming the serviceListener starts this service. This method does not return.
    [listener resume];
    
    /*
    // 这个方法只能用在 XPC 服务中, 具 resume 后, 不会返回, 用在其它地方会报错
    //NSXPCListener *listener = [NSXPCListener serviceListener];
    //[listener resume];
    // 其它地方用下面方法或者 [NSXPCListener anonymousListener]
    NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.Anywii.CoreMediaIOPluginDemo"];
    listener.delegate = [HZXPCDelegate manager];
    [listener resume];*/
    
    return 0;
}
