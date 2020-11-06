//
//  AppDelegate.m
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/16.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSLog(@"ScreenBounds:%@", NSStringFromCGRect([UIScreen mainScreen].bounds));
    return YES;
}


@end
