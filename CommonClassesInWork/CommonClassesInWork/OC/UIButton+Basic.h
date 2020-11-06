//
//  UIButton+Basic.h
//  xing
//
//  Created by admin on 2018/12/13.
//  Copyright © 2018 萧小扉~. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (Basic)

/// 参数 title font
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor;

/// 参数 title font titleColor image cornerRadius
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                 cornerRadius:(CGFloat)cornerRadius;

/// 参数 image
- (instancetype)initWithImage:(nullable UIImage *)image;

- (instancetype)initWithImage:(nullable UIImage *)image
                selectedImage:(nullable UIImage *)selectedImage;

/// 参数 title font titleColor backgroundImage
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundImage:(nullable UIImage *)backgroundImage;

/// 参数 title font titleColor backgroundImage cornerRadius
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundImage:(nullable UIImage *)backgroundImage
                 cornerRadius:(CGFloat)cornerRadius;

/// 参数 title font titleColor backgroundColor
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundColor:(nullable UIColor *)backgroundColor;

/// 参数 title font titleColor backgroundColor cornerRadius
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundColor:(nullable UIColor *)backgroundColor
                 cornerRadius:(CGFloat)cornerRadius;

/// 参数 title font titleColor image
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                        image:(nullable UIImage *)image;

/// 参数 title font titleColor image
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                        image:(nullable UIImage *)image
                selectedImage:(nullable UIImage *)selectedImage;

/// 参数 title font titleColor image cornerRadius
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                        image:(nullable UIImage *)image
                 cornerRadius:(CGFloat)cornerRadius;

/// 参数 title font titleColor image backgroundImage cornerRadius
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                        image:(nullable UIImage *)image
              backgroundImage:(nullable UIImage *)backgroundImage
                 cornerRadius:(CGFloat)cornerRadius;

/// 很多参数
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
             selectTitleColor:(nullable UIColor *)selectTitleColor
        highlightedTitleColor:(nullable UIColor *)highlightedTitleColor
              backgroundColor:(nullable UIColor *)backgroundColor
                        image:(nullable UIImage *)image
                selectedImage:(nullable UIImage *)selectedImage
             highlightedImage:(nullable UIImage *)highlightedImage
              backgroundImage:(nullable UIImage *)backgroundImage
      selectedBackgroundImage:(nullable UIImage *)selectedBackgroundImage
   highlightedBackgroundImage:(nullable UIImage *)highlightedBackgroundImage
                 cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
