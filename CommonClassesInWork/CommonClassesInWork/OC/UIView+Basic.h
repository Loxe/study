//
//  UIView+Basic.h
//  huiduji
//
//  Created by 黄镇 on 2018/10/17.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Basic)

@property (nonatomic, assign) CGFloat   x;
@property (nonatomic, assign) CGFloat   y;
@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat   width;
@property (nonatomic, assign) CGFloat   height;
@property (nonatomic, assign) CGPoint   origin;
@property (nonatomic, assign) CGSize    size;
@property (nonatomic, assign) CGFloat   bottom;
@property (nonatomic, assign) CGFloat   right;
@property (nonatomic, assign) CGFloat   centerX;
@property (nonatomic, assign) CGFloat   centerY;

/// 获取控制器
- (UIViewController *)viewController;

///设置特定角的角半径
- (void)setCornerRadius:(CGFloat)cornerRadius withRoundingCorners:(UIRectCorner)corners;
///设置frame
- (void)setFrameWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height;

/**
 遍历所有子视图，包含子视图的子视图

 @param block 遍历要执行的block
 */
- (void)enumerateAllSubviewsUsingBlock:(void (^)(UIView *subView))block;

@end

NS_ASSUME_NONNULL_END
