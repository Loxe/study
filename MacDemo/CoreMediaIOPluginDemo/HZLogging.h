//
//  HZLogging.h
//  MacDemo
//
//  Created by JinTao on 2020/12/8.
//

#ifndef HZLogging_h
#define HZLogging_h

#define DLog(fmt, ...) NSLog((@"CMIOMS: " fmt), ##__VA_ARGS__)
#define DLogFunc(fmt, ...) NSLog((@"CMIOMS: %s " fmt), __FUNCTION__, ##__VA_ARGS__)

#endif /* HZLogging_h */
