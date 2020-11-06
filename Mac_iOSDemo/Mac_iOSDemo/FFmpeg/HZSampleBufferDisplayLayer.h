//
//  HZSampleBufferDisplayLayer.h
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/28.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import <AVFoundation/AVSampleBufferDisplayLayer.h>

NS_ASSUME_NONNULL_BEGIN

/// 用这个来渲染简单很多, 但截图和录像, AVSampleBufferDisplayLayer的图像画不出来, 用Metal或OpenGL能正常画出来
@interface HZSampleBufferDisplayLayer : AVSampleBufferDisplayLayer

@property (nonatomic, assign) BOOL shouldMaskToRound;

@end

NS_ASSUME_NONNULL_END
