//
//  HZMTKView.h
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/29.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVAnimation.h>
#import "HZAssetWriterManager.h"

NS_ASSUME_NONNULL_BEGIN

/// 图像反转方式
typedef NS_OPTIONS(NSUInteger, HZMTKViewReversalMode) {
    /// 没有反转
    HZMTKViewReversalModeNone       = 0 << 0,
    /// 左右反转
    HZMTKViewReversalModeLeftRight  = 1 << 0,
    /// 上下反转
    HZMTKViewReversalModeTopBottom  = 1 << 1,
};

typedef NS_ENUM(NSInteger, HZMTKViewDrawMode) {
    // ffmpeg里的数据判断不出用什么方式画
    HZMTKViewDrawModeUnknow = -1,
    // 以圆形显示
    HZMTKViewDrawModeDrawAsCircle,
    // 以方形显示
    HZMTKViewDrawModeAsRectangle,
};

/// 只实现了N12格式
@interface HZMTKView : MTKView

@property (nonatomic, strong) HZAssetWriterManager *assetWriteManager;
@property (nonatomic, copy) AVLayerVideoGravity videoGravity; ///< 图片的填充方式
@property (nonatomic, assign) HZMTKViewDrawMode drawMode; ///< 不要每帧都去设置, 里面有线程切换, 较耗资源
@property (nonatomic, assign) HZMTKViewReversalMode reversalMode;
@property (nonatomic, assign) float rotateAngleInRadians; ///< 如果可能, 尽量在ffmpeg里面传数据, 减少线程切换, 且降低代码耦合度

- (void)drawPixelBuffer:(CVPixelBufferRef)pixelBuffer withRotateAngleInRadians:(float)rotateAngleInRadians drawMode:(HZMTKViewDrawMode)drawMode;

- (void)screenShotWithFilePath:(NSString *)filePath withCompletionHandler:(void (^)(UIImage * _Nullable image))completionHandler;
- (void)startRecordWithFilePath:(NSString *)filePath;
- (void)stopRecord;
- (void)freePictureData;

@end

NS_ASSUME_NONNULL_END
