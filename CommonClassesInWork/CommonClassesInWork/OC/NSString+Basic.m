//
//  NSString+Basic.m
//  huiduji
//
//  Created by 段雪松 on 18/10/12.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import "NSString+Basic.h"
#import <CommonCrypto/CommonDigest.h>
#import <SystemConfiguration/CaptiveNetwork.h>


static NSString *HZUserDefaultsLanguageTypeKey = @"HZLanguageTypeKey";

@implementation NSString (Basic)

+ (NSString *)getSSIDString {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    //HZLog(@"Supported interfaces: %@", ifs);
    NSDictionary *info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        //HZLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) { break; }
    }
    
    return  info[(__bridge NSString *)kCNNetworkInfoKeySSID];
}

+ (instancetype)stringWithHex:(NSInteger)hex {
    return [NSString stringWithFormat:@"%lX", (long)hex];
}

- (NSData *)hexStringToData {
    NSString *string = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([string hasPrefix:@"0x"] ||
        [string hasPrefix:@"0X"]) {
        string = [string stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""];
    }
    int len = (int)string.length / 2; // Target length
    unsigned char *buf = (unsigned char *)malloc(len);
    memset(buf, 0, len);
    unsigned char *whole_byte = buf;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < len; i++) {
        byte_chars[0] = [string characterAtIndex:i * 2];
        byte_chars[1] = [string characterAtIndex:i * 2 + 1];
        *whole_byte = strtol(byte_chars, NULL, 16);
        NSLog(@"%x", *whole_byte);
        whole_byte++;
    }
    NSData *data = [NSData dataWithBytes:buf length:len];
    free(buf);
    
    return data;
}

- (NSString *)localizedWith:(NSString *)key {
    NSString *language = [[NSUserDefaults standardUserDefaults] objectForKey:HZUserDefaultsLanguageTypeKey];
    if (!(language == nil)) {
        NSString *path = [[NSBundle mainBundle] pathForResource:language ofType:@"lproj"];
        if (!path) {
            return self;
        }
        
        return [[NSBundle bundleWithPath:path] localizedStringForKey:key value:self table:nil];
    }
    
    NSString *localeSymbolString = [NSLocale preferredLanguages].firstObject;
    if (!localeSymbolString) {
        return self;
    }
    
    //大陆版，港版，美版 所标示的字符串不同，比如简体中文下，行货为：zh-Hant，美版为zh-Hant-US
    NSString *localeSymbolPrefixString = localeSymbolString;
    
    BOOL isLocaled = false;
    for (NSString *localedStringInMainBundle in [[NSBundle mainBundle] localizations]) {
        if ([localeSymbolPrefixString hasPrefix:localedStringInMainBundle]) {
            isLocaled = YES;
            break;
        }
    }
    
    if (isLocaled) {
        NSString *localizedString = NSLocalizedString(key, self);
        if ([localizedString isEqualToString:key]) {
            return self;
        } else {
            return localizedString;
        }
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        if (path == nil) {
            return self;
        }
        return [[NSBundle bundleWithPath:path] localizedStringForKey:key value:self table:nil];
    }
}

- (CGSize)sizeWithWidth:(CGFloat)width font:(UIFont *)font {
    CGSize size = [self boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : font} context:nil].size;
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

- (BOOL)isValidateEmail {
    NSString *regex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

- (BOOL)isValidateMobileNumber {
    NSString *regex = @"^1(3[0-9]|4[57]|5[0-35-9]|8[0-9]|7[06-8])\\d{8}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

- (NSString *)md5String {
    //要进行UTF8的转码
    const char* input = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02X", result[i]];
    }
    
    return digest;
}

- (BOOL)isAllDigit {
    if (self.length <= 0) {
        return NO;
    }
    unichar c;
    for (int i = 0; i < self.length; i++) {
        c = [self characterAtIndex:i];
        if (!isdigit(c)) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)isIPV4String {
    NSArray<NSString *> *subStringsArray = [self componentsSeparatedByString:@"."];
    if (subStringsArray.count != 4) {
        return NO;
    }
    
    for (int i = 0; i < 4; i++) {
        NSString *subString = subStringsArray[i];
        NSInteger subValue = subString.integerValue;
        if (subValue > 255 ||
            subValue < 0 ||
            (i == 0 && subValue == 0) ||
            ![subString isAllDigit]) {
            return NO;
        }
    }
    
    return YES;
}

@end
