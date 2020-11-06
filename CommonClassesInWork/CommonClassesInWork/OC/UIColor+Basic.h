//
//  UIColor+Basic.h
//  huiduji
//
//  Created by 段雪松 on 18/10/12.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Basic)

+ (UIColor *)colorWithHex:(NSUInteger)hex;
+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha;

@end
