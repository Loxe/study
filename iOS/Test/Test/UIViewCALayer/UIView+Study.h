//
//  UIView+Study.h
//  Test
//
//  Created by JinTao on 2020/10/13.
//  Copyright © 2020 vine. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 1 transform
 设置了transform后, 会修改其frame属性, 进而会调到ViewController的ViewDidLayoutSubViews方法, 如果在里面设置frame, 会造成动画错乱
 修改transform后, 只有frame会变, layer的position, anchorPoint不会变, view的center也不会变
 view的center其实是layer的position, 而不是view的中心, 而layer的position是其anchorPoint在父视图的坐标
 
 2 autoresizingMask translatesAutoresizingMaskIntoConstraints
 普通的view的autoresizingMask为UIViewAutoresizingNone;
 UIViewController的view的autoresizingMask, 系统会在某个时刻附值UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight, 在viewDidLayoutSubviews之前;
 当view的translatesAutoresizingMaskIntoConstraints为YES时, 系统会把autoresizingMask转成约束, 但这个约束在view的constraints里查不到; 如果为NO, 刚不会转成约束, 这时view的宽高值不会和屏幕一样, 可能为0
 */
@interface UIView ()

@end

NS_ASSUME_NONNULL_END
