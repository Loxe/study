//
//  BuiltinFunction.c
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/10/22.
//  Copyright © 2020 JinTao. All rights reserved.
//

#include "BuiltinFunction.h"

/// 编译器位运算函数
void __builtin_test() {
    printf("%lu %lu %lu\n", sizeof(long), sizeof(long long), sizeof(int));
    
    // int __builtin_ffs (unsigned int x)  各函数参数类型都是unsigned int, 返回类型都是int
    
    int a = __builtin_clz(0b111111111111111111111111111111); // 返回前面0的个数, 参数是int, 所以为32位前面连续0的个数
    printf("%d\n", a);
    // IJK里计算视频宽度对齐的方式, 为什么要这么算, 还不大清楚, 其实在这个demo里面, 只要变化后的宽度是linesize[0]就行, 而且这个宽度生成CVPixelBuffer后的bytesPerLine也不是这个计算方式
    // 其意义是从遇到1开始那位<<1, 且从这位开始后面都补0
    a = 1 << (sizeof(int) * 8 - __builtin_clz(512));
    printf("%d\n", a);
    
    a = __builtin_ffs(0b1100); // 返回最后一位1的是从后娄第几位
    printf("%d\n", a);
    
    a = __builtin_ctz(0b1100); // 返回后面0的个数
    printf("%d\n", a);
    
    a = __builtin_popcount(0b10001100); // 返回二进制表示中1的个数
    printf("%d\n", a);
    
    a = __builtin_parity(0b1010011100); // 返回奇偶校验位，也就是参数的二进制的1的个数模2的结果
    printf("%d\n", a);
    
    // 此外，这些函数都有相应的usigned long和usigned long long版本，只需要在函数名后面加上l或ll就可以了，比如 int __builtin_clzll
    a = __builtin_ctzll(0b1010011100);
    printf("%d\n", a);
}
