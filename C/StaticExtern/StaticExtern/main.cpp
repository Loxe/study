//
//  main.cpp
//  StaticExtern
//
//  Created by admin on 2019/10/11.
//  Copyright © 2019 vine. All rights reserved.
//


#include "ThreadLock.c"

int main(int argc, char *argv[])
{
    printf("开始");
    conditionLock();
    printf("结束");
    return 0;
}
