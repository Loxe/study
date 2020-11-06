//
//  UIImage+Basic.h
//  huiduji
//
//  Created by 段雪松 on 18/10/12.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Basic)

/**
 生成单色图片

 @param tintColor 颜色
 @return 图片
 */
- (UIImage *)imageWithTintColor:(UIColor *)tintColor;

/**
 生成渐变色图片

 @param tintColor 颜色
 @return 图片
 */
- (UIImage *)imageWithGradientTintColor:(UIColor *)tintColor;

/**
 将图片变灰

 @return 新图片
 */
- (UIImage *)grayImage;

/**
 生成指定颜色大小的图片

 @param color 颜色
 @param size 大小
 @return 图片
 */
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

/**
 生成指定颜色大小的椭圆图片
 
 @param color 颜色
 @param size 大小
 @return 图片
 */
+ (UIImage *)ellipseImageWithColor:(UIColor *)color size:(CGSize)size;


/**
 绽放图片至指定大小

 @param size 大小
 @return 新图片
 */
- (UIImage *)zoomImageToSize:(CGSize)size;

/**
 重新创建改变亮度，饱和度，对比度的图片
 
 @param brightness 亮度，-1 - 1，默认为0
 @param saturation 饱和度 0 - 2，默认为1
 @param contrast 对比度 0 - 4，默认为1
 @return 新的图片
 */
- (UIImage *)imageWithBrightness:(CGFloat)brightness saturation:(CGFloat)saturation contrast:(CGFloat)contrast;

- (UIImage *)highlightedImage;

@end
