//
//  main.c
//  Test
//
//  Created by Apple on 2020/10/1.
//  Copyright © 2020 vine. All rights reserved.
//

#ifndef main_c
#define main_c
#include "swap.c"

int buf[2] = {1, 2};
void swap(void);

int main() {
    swap();  /* 引用符号swap */
    return 0;
}

#endif


/**
 链接的步骤如下
 1：符号解析
 程序中有定义和引用的符号（包括变量和函数等）
 编译器将定义的符号存放在符号表中。
 符号解析就是将符号的引用和符号的定义建立关联
 
 2：重定位
 将多个代码段与数据段分别合并为一个单独的代码段和数据段
 计算每个定义的符号在虚拟地址空间中的绝对地址
 将可执行文件中的符号引用处的地址修改为重定位后的地址信息
 */

/**
 ELF目标文件(Unix下的Mach-o文件)
 ELF的目标文件分为三类：
 1 可重定位目标文件（.o）
 其代码和数据可和其他可重定位文件合并为可执行文件
 每个 .o 文件由对应的 .c 文件生成
 每个 .o 文件的代码和数据地址都是从0开始的偏移, 在mac的Mach-o文件不是从0开始的, 查看汇编指令: objdump -d mainc(文件名)
 
 2 可执行目标文件（默认为a.out）
 包含的代码和数据可以被直接复制到内存并执行
 代码和数据的地址是虚拟地址空间中的地址
 
 3 共享的目标文件（.so 共享库）
 特殊的可重定位目标文件，能在装载到内存或运行时自动被链接，称为共享库文件
 */

/**
 ELF重定位目标文件结构
 ELF头: 包括16字节的标识信息、文件类型（.o，exec，.so）、机器类型（如Intel 80386）、节头表的偏移、节头表的表项大小及表项个数。
 .text节: 编译后的代码部分
 .rodata节: 只读数据，如 printf用到的格式串、switch跳转表等。
 .data节: 已初始化的全局变量和静态变量。
 .bss节: 未初始化全局变量和静态变量，仅是占位符，不占据任何磁盘空间。区分初始化和非初始化是为了空间效率。
 .symtab节: 存放函数和全局变量（符号表）的信息，它不包括局部变量。
 .rel.text节: .text节的重定位信息，用于重新修改代码段的指令中的地址信息。
 .rel.data节: .data节的重定位信息，用于对被模块使用或定义的全局变量进行重定位的信息。
 .debug节: 调试用的符号表（gcc -g）
 .strtab节: 包含 .symtab节和 .debug节中的符号及节名
 节头表（Section header table）: 包含每个节的节名在.strtab节中的偏移、节的偏移和节的大小.
 */


/*
 //ELF头 （ELF Header）
 // ELF头位于ELF文件的开始，其包含了文件结构的说明信息。其结构体定义如下：
#define EI_NIDENT 16
typedef struct {
    unsigned char e_ident[EI_NIDENT];
    uint16_t      e_type;
    uint16_t      e_machine;
    uint32_t      e_version;
    ElfN_Addr    e_entry;
    ElfN_Off      e_phoff;
    ElfN_Off      e_shoff;
    uint32_t      e_flags;
    uint16_t      e_ehsize;
    uint16_t      e_phentsize;
    uint16_t      e_phnum;
    uint16_t      e_shentsize;
    uint16_t      e_shnum;
    uint16_t      e_shstrndx;
} ElfN_Ehdr;
 查看指令: mac下这个命令不行
 readelf -h main.o(.o文件名)
 readelf -l mainc(可执行文件名)
 */

/**
 ELF可重定位文件结构:
 ELF头
 程序头表(可选)
 节1
 ...
 节n
 ...
 节头表
 */

 /**
  ELF可执行目标文件结构:
  ELF头
  程序头表
  段1
  段2
  ...
  节头表
  */


/**
 强符号：函数名和已初始化的全局变量名是强符号。
 弱符号：未初始化的全局变量名是弱符号。
 
 链接器对符号的解析规则
 符号解析时，只能有一个确定的定义（即每个符号仅占一处存储空间）。
 所以，如果碰到符号存在多重定义时，就得有相应的处理规则：
 Rule 1：强符号不能多次定义
 强符号只能被定义一次，否则链接错误。
 Rule 2：若一个符号被定义为一次强符号和多次弱符号，则按强符号定义为准。
 Rule 3：若有多个弱符号定义，则任选其中一个。
 */


/**
 Mach-o文件分析命令otool
 查看fat headers信息: otool -f mainc(文件名)
 查看archive header信息: otool -a mainc(文件名)
 查看Mach-O头结构: otool -h mainc(文件名)
 查看load commands: otool -l mainc(文件名)
 查看依赖的动态库,包括动态库名称、当前版本号、兼容版本号: otool -L mainc(文件名)
 查看支持的框架: otool -D mainc(文件名)
 查看text section: otool -t -v mainc(文件名)
 查看data section: otool -d mainc(文件名)
 查看Objective-C segment: otool -o mainc(文件名)
 查看symbol table: otool -I mainc(文件名)
 获取所有方法名称: otool -v -s __TEXT __objc_methname  mainc(文件名)
 */
