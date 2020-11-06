//
//  Test1.hpp
//  Block1
//
//  Created by admin on 2019/10/10.
//  Copyright © 2019 vine. All rights reserved.
//

#ifndef Test1_hpp
#define Test1_hpp

#include <stdio.h>

extern int XResultShouldShowDeviceUnaddedError;



void test2() {
    //(void (*)())&structTest1(1);
    printf("%p\n", &XResultShouldShowDeviceUnaddedError);
}

#endif /* Test1_hpp */
