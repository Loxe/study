//
//  HZAutoreleasePoolTest.m
//  Test
//
//  Created by admin on 2019/10/12.
//  Copyright © 2019 vine. All rights reserved.
//

#import "HZAutoreleasePoolTest.h"

@implementation HZAutoreleasePoolTest

+ (void)test {
    HZLog(@"test1 begin!");
    for (int i = 0; i < 100 * 2; i++) {
//        @autoreleasepool {
//            NSString *str = [NSString stringWithFormat:@"hi + %d", i];
//        }
    }
    HZLog(@"test1 finished!");
}

// 添加一个监听者
+ (void)addRunLoopObserver {
    // 1. 创建监听者
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopEntry:
                HZLog(@"进入RunLoop");
                break;
            case kCFRunLoopBeforeTimers:
                HZLog(@"即将处理Timer事件");
                break;
            case kCFRunLoopBeforeSources:
                HZLog(@"即将处理Source事件");
                break;
            case kCFRunLoopBeforeWaiting:
                HZLog(@"即将休眠");
                break;
            case kCFRunLoopAfterWaiting:
                HZLog(@"被唤醒");
                break;
            case kCFRunLoopExit:
                HZLog(@"退出RunLoop");
                break;
            default:
                break;
        }
    });
    
    // 2. 添加监听者
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
}

@end
