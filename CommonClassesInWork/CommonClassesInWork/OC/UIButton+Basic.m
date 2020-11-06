//
//  UIButton+Basic.m
//  xing
//
//  Created by admin on 2018/12/13.
//  Copyright © 2018 萧小扉~. All rights reserved.
//

#import "UIButton+Basic.h"

@implementation UIButton (Basic)

- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:nil
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:0.f];
}

- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                 cornerRadius:(CGFloat)cornerRadius {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:nil
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:cornerRadius];
}

- (instancetype)initWithImage:(nullable UIImage *)image {
    return [self initWithTitle:nil
                          font:nil
                    titleColor:nil
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:image
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:0.f];
}

- (instancetype)initWithImage:(UIImage *)image selectedImage:(UIImage *)selectedImage {
    return [self initWithTitle:nil
                          font:nil
                    titleColor:nil
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:image
                 selectedImage:selectedImage
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:0.f];
}

- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundImage:(nullable UIImage *)backgroundImage {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:nil
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:backgroundImage
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:0.f];
}


- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                        image:(nullable UIImage *)image {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:image
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:0.f];
}

- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundImage:(nullable UIImage *)backgroundImage
                 cornerRadius:(CGFloat)cornerRadius {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:nil
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:backgroundImage
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:cornerRadius];
}

- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundColor:(nullable UIColor *)backgroundColor {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:backgroundColor
                         image:nil
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:0.f];
}

/// 参数 title titleColor backgroundColor cornerRadius
- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
              backgroundColor:(nullable UIColor *)backgroundColor
                 cornerRadius:(CGFloat)cornerRadius {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:backgroundColor
                         image:nil
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:cornerRadius];
}

- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                        image:(nullable UIImage *)image
                selectedImage:(nullable UIImage *)selectedImage {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:image
                 selectedImage:selectedImage
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:0.f];
}

- (instancetype)initWithTitle:(nullable NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(nullable UIColor *)titleColor
                        image:(nullable UIImage *)image
                 cornerRadius:(CGFloat)cornerRadius {
    return [self initWithTitle:title
                          font:nil
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:image
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:nil
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:cornerRadius];
}

- (instancetype)initWithTitle:(NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(UIColor *)titleColor
                        image:(UIImage *)image
              backgroundImage:(UIImage *)backgroundImage
                 cornerRadius:(CGFloat)cornerRadius {
    return [self initWithTitle:title
                          font:font
                    titleColor:titleColor
              selectTitleColor:nil
         highlightedTitleColor:nil
               backgroundColor:nil
                         image:image
                 selectedImage:nil
              highlightedImage:nil
               backgroundImage:backgroundImage
       selectedBackgroundImage:nil
    highlightedBackgroundImage:nil
                  cornerRadius:cornerRadius];
}

- (instancetype)initWithTitle:(NSString *)title
                         font:(nullable UIFont *)font
                   titleColor:(UIColor *)titleColor
             selectTitleColor:(UIColor *)selectTitleColor
        highlightedTitleColor:(UIColor *)highlightedTitleColor
              backgroundColor:(UIColor *)backgroundColor
                        image:(UIImage *)image
                selectedImage:(UIImage *)selectedImage
             highlightedImage:(UIImage *)highlightedImage
              backgroundImage:(UIImage *)backgroundImage
      selectedBackgroundImage:(UIImage *)selectedBackgroundImage
   highlightedBackgroundImage:(UIImage *)highlightedBackgroundImage
                 cornerRadius:(CGFloat)cornerRadius {
    if (self = [super init]) {
        if (title) {
            [self setTitle:title forState:UIControlStateNormal];
        }
        if (font) {
            self.titleLabel.font = font;
        }
        if (titleColor) {
            [self setTitleColor:titleColor forState:UIControlStateNormal];
        }
        if (selectTitleColor) {
            [self setTitleColor:selectTitleColor forState:UIControlStateSelected];
        }
        if (highlightedTitleColor) {
            [self setTitleColor:highlightedTitleColor forState:UIControlStateHighlighted];
            [self setTitleColor:highlightedTitleColor forState:UIControlStateHighlighted | UIControlStateSelected];
        }
        if (backgroundColor) {
            self.backgroundColor = backgroundColor;
        }
        if (image) {
            [self setImage:image forState:UIControlStateNormal];
        }
        if (selectedImage) {
            [self setImage:selectedImage forState:UIControlStateSelected];
            [self setImage:highlightedImage forState:UIControlStateSelected | UIControlStateHighlighted];
        }
        if (highlightedImage) {
            [self setImage:highlightedImage forState:UIControlStateHighlighted];
        }
        if (backgroundImage) {
            [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        }
        if (selectedBackgroundImage) {
            [self setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
        }
        if (highlightedBackgroundImage) {
            [self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
        }
        if (cornerRadius > 0) {
            self.clipsToBounds = YES;
            self.layer.cornerRadius = cornerRadius;
        }
    }
    
    return self;
}

@end
