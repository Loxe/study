//
//  UIScreen+Basic.m
//  huiduji
//
//  Created by 黄镇 on 2018/10/18.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import "UIScreen+Basic.h"

@implementation UIScreen (Basic)

+ (BOOL)isNotchScreen {
    if (@available(iOS 11.0, *)) {
        CGFloat iPhoneNotchDirectionSafeAreaInsets = 0;
        UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].windows[0].safeAreaInsets;
        switch ([UIApplication sharedApplication].statusBarOrientation) {
            case UIInterfaceOrientationPortrait:{
                iPhoneNotchDirectionSafeAreaInsets = safeAreaInsets.top;
            }
                break;
            case UIInterfaceOrientationLandscapeLeft:{
                iPhoneNotchDirectionSafeAreaInsets = safeAreaInsets.left;
            }
                break;
            case UIInterfaceOrientationLandscapeRight:{
                iPhoneNotchDirectionSafeAreaInsets = safeAreaInsets.right;
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown:{
                iPhoneNotchDirectionSafeAreaInsets = safeAreaInsets.bottom;
            }
                break;
            default:
                iPhoneNotchDirectionSafeAreaInsets = safeAreaInsets.top;
                break;
        }
        return iPhoneNotchDirectionSafeAreaInsets > 20;
    } else {
        return NO;
    }
}

@end
