//
//  HZIPCGLobalHeader.h
//  MacDemo
//
//  Created by JinTao on 2020/12/14.
//

#ifndef HZIPCGLobalHeader_h
#define HZIPCGLobalHeader_h

#define HZLog(fmt, ...) NSLog((@"CMIOMS: %s line:%d 打印内容:" fmt), __func__, __LINE__, ##__VA_ARGS__)

#define HZMachBootstrapPortName @"com.Anywii.MacDemo"

typedef NS_ENUM(NSUInteger, HZIPCMachMessageID) {
    HZIPCMachMessageIDConnect = 1,
    HZIPCMachMessageIDFrame,
    HZIPCMachMessageIDStop,
};

#endif /* HZIPCGLobalHeader_h */
