//
//  Compile.c
//  Test
//
//  Created by JinTao on 2020/9/27.
//  Copyright © 2020 vine. All rights reserved.
//

#ifndef Compile_h
#define Compile_h
//#include <stdio.h>

int test() {
    int a;
    int b;
    return a + b;
}

int main() {
    test();
    return 0;
}

#endif /* Compile_h */

/**
 可执行文件的生成需要经过预处理、编译、汇编和链接这4个过程
 预处理的工作：
 删除 #define 并展开宏定义
 处理所有的条件预编译指令，如 "#if"，"#ifdef"，"#endif"等
 插入头文件到 "#include" 处，可以递归方式进行处理
 删除所有的注释
 添加行号和文件名标识，以便编译时编译器产生调试用的行号信息
 保留所有 #pragma 编译指令（编译器需要用）
 命令示例如下：
 gcc -E hello.c -o hello.i

 编译的工作:
 编译过程就是将预处理后得到的预处理文件（如hello.i）进行词法分析、语法分析、语义分析、优化后，生成汇编代码文件。
 经过编译后，得到的汇编代码文件（如，hello.S）还是一个可读的文本文件。
 命令示例如下：
 gcc -S hello.i -o hello.s
 gcc -S hello.c -o hello.s

 汇编的工作:
 汇编器将编译得到的汇编代码文件转换成机器指令序列。
 汇编的结果是一个可重定位目标文件（如，hello.o）其中包含的是不可读的二进制代码。
 命令示例如下：
 gcc -c hello.s -o hello.o
 gcc -c hello.c -o hello.o
 as hello.s -o hello.o

 链接的工作:
 链接过程将多个可重定位目标文件合并以生成可执行目标文件。
 命令示例如下：
 gcc -static -o myproc main.o test.o
 ld -static -o myproc main.o test.o
 */
