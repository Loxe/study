//
//  swap.c
//  Test
//
//  Created by Apple on 2020/10/1.
//  Copyright © 2020 vine. All rights reserved.
//

#ifndef swap_c
#define swap_c

#include "main.c"

extern int buf[];

int *bufp0 = &buf[0];  /* 定义符号bufp0，引用符号buf */

static int *bufp1;

void swap() { /* 定义符号swap */
    int temp;
    bufp1 = &buf[1];
    temp = *bufp0;
    *bufp0 = *bufp1;
    *bufp1 = temp;
}

#endif
