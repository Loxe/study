//
//  HZIPCGLobalHeader.h
//  MacDemo
//
//  Created by JinTao on 2020/12/14.
//

#ifndef HZIPCGLobalHeader_h
#define HZIPCGLobalHeader_h

#define HZMachBootstrapPortName @"com.Anywii.MacDemo"

typedef NS_ENUM(NSUInteger, HZIPCMachMessageID) {
    HZIPCMachMessageIDConnect = 1,
    HZIPCMachMessageIDFrame,
    HZIPCMachMessageIDStop,
};

#endif /* HZIPCGLobalHeader_h */
