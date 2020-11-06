//
//  main.m
//  Test
//
//  Created by admin on 2019/10/12.
//  Copyright © 2019 vine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

static __attribute__((constructor))
void my_constructor() {
    NSLog(@"%s", __func__);
}

void my_disconstructor() {
    NSLog(@"%s", __func__);
}

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
