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
    
    return 0;
}
