//
//  HZOpenGLView.h
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/11/17.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HZOpenGLView : UIView

- (void)drawPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
