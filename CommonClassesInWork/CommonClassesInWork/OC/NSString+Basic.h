//
//  NSString+Basic.h
//  huiduji
//
//  Created by 段雪松 on 18/10/12.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Basic)

///获取wifi名
+ (NSString *)getSSIDString;

///由16进制初始化
+ (instancetype)stringWithHex:(NSInteger)hex;

/// 16进制的字符串转NSData
- (NSData *)hexStringToData;

/**
 国际化

 @param key 键
 @return 国际化后的字符串
 */
- (NSString *)localizedWith:(NSString *)key;
///计算文字大小
- (CGSize)sizeWithWidth:(CGFloat)width font:(UIFont *)font;
///是不是邮箱
- (BOOL)isValidateEmail;
///是不是手机号
- (BOOL)isValidateMobileNumber;
///md5化
- (NSString *)md5String;

/**
 是不是都是数字
 */
- (BOOL)isAllDigit;

/**
 是不是IPV4地址
 */
- (BOOL)isIPV4String;

@end
