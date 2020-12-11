//
//  HZPlugInMain.mm
//  CoreMediaIOPluginDemo
//
//  Created by JinTao on 2020/12/8.
//

#import <CoreMediaIO/CMIOHardwarePlugIn.h>

#import "HZPlugInInterface.h"
#import "HZLogging.h"

#import "HZXPCDelegate.h"

/**
 .plugin安装目录:/Library/CoreMediaIO/Plug-Ins/DAL/
 Packaging -> Wrapper Extension: 一定要设置为plugin, xcode默认为bundle, 但 CoreMediaIO 打包成bundle, 插件无效
 
 命令操作:
 lsof(lists openfiles)
 ps(Process Status) -ef
 */

//! PlugInMain is the entrypoint for the plugin
extern "C" {
    void* HZPlugInMain(CFAllocatorRef allocator, CFUUIDRef requestedTypeUUID) {
        DLogFunc(@"");
        if (!CFEqual(requestedTypeUUID, kCMIOHardwarePlugInTypeID)) {
            return 0;
        }

        return PlugInRef();
    }
}
