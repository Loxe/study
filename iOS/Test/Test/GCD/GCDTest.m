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

@end
