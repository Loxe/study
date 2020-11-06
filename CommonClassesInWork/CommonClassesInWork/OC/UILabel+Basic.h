//
//  UILabel+Basic.h
//  xing
//
//  Created by admin on 2018/12/13.
//  Copyright © 2018 萧小扉~. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Basic.h"

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (Basic)

///参数 text font textColor
- (instancetype)initWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor;
///参数 text font textColor textAlignment
- (instancetype)initWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor textAlignment:(NSTextAlignment)textAlignment;
///设置frame
- (void)setFrameWithX:(CGFloat)x y:(CGFloat)y maxWidth:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
