//
//  GCDTest.m
//  Test
//
//  Created by JinTao on 2020/9/5.
//  Copyright © 2020 vine. All rights reserved.
//

#import "GCDTest.h"

@implementation GCDTest

+ (void)groupTest {
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    HZLog(@"加入");
    HZLog(@"加入");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 异步2秒后离开
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), queue, ^{
        HZLog(@"即将离开 - 1");
        dispatch_group_leave(group);
        HZLog(@"已经离开 - 1");
    });
    
    // 异步3秒后离开
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), queue, ^{
        HZLog(@"即将离开 - 2");
        dispatch_group_leave(group);
        HZLog(@"已经离开 - 2");
    });
    HZLog(@"都完成了");
    dispatch_group_notify(group, queue, ^{
        // enter leave 成对后才能进入
        HZLog(@"都完成了 notify");
    });
    HZLog(@"开始等待");
    // 只要达到时间，或者 group 完成（有enter,leave时要成对匹配），都会继续执行后面的代码
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)));
    //sleep(3);
    HZLog(@"等待结束");
}

+ (void)waitTest {
    // 监听这个block的执行情况
    dispatch_block_t block = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_DETACHED, QOS_CLASS_DEFAULT, 0, ^{
        sleep(3);
    });
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, block);
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC));
    BOOL shouldBlock = YES;
    if (shouldBlock) {
        // 会阻塞当前线程, 在规定的时间内block执行完了, 返回0, 一个block只能执行一次, 也只能等待一次
        dispatch_block_wait(block, timeout);
    } else {
        // 不会阻塞当前线程
        dispatch_block_notify(block, globalQueue, ^{
            //block执行完后要执行的block
        });
    }
}

@end
