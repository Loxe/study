//
//  CALayer+Study.h
//  Test
//
//  Created by JinTao on 2020/10/12.
//  Copyright © 2020 vine. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 frame.origin.x = position.x - anchorPoint.x * bounds.size.width
 frame.origin.y = position.y - anchorPoint.y * bounds.size.height
 anchorPoint的默认值为(0.5,0.5)
 修改position只会影响frame, 不影响anchorPoint
 修改anchorPoint只会影响frame, 不影响position
 修改frame只会影响position, 不影响anchorPoint
 position是anchorPoint在父视图的坐标
 */
@interface CALayer ()

@end

NS_ASSUME_NONNULL_END
