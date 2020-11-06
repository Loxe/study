//
//  UILabel+Basic.m
//  xing
//
//  Created by admin on 2018/12/13.
//  Copyright © 2018 萧小扉~. All rights reserved.
//

#import "UILabel+Basic.h"
#import "NSString+Basic.h"

@implementation UILabel (Basic)

- (instancetype)initWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor {
    return [self initWithText:text font:font textColor:textColor textAlignment:NSTextAlignmentLeft];
}

- (instancetype)initWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor textAlignment:(NSTextAlignment)textAlignment {
    if (self = [super init]) {
        self.text = text;
        self.font = font;
        self.textColor = textColor;
        self.numberOfLines = 0;
        self.textAlignment = textAlignment;
    }
    
    return self;
}

- (void)setFrameWithX:(CGFloat)x y:(CGFloat)y maxWidth:(CGFloat)maxWidth {
    CGSize size = [self.text sizeWithWidth:maxWidth font:self.font];
    self.frame = CGRectMake(x, y, size.width, size.height);
}

@end
