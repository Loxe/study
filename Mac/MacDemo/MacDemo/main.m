//
//  main.m
//  MacDemo
//
//  Created by JinTao on 2020/12/7.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    return NSApplicationMain(argc, argv);
}


/**
 mac开发学习记录:
 
 如果使用了非系统的第3方framework或者自己开发的framework，Code Signing 里面Other Code Signing Flags 必须设置为 --deep，否则无法正常打包发布到Mac Appstore。(自己没有验证)
 
 Capabilities -> App Sandbox:
 Outgoing Connections: 如果你的应用要访问服务器的API接口，必须打开
 Hardware -> Printing: 必须选择打开，否则审核不通过
 File Access -> User Selected File: 如果你需要让用户选择访问本地的文件，选择读/写权限
 */
