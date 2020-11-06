//
//  NSData+Basic.m
//  CommonClassesInWork
//
//  Created by admin on 2019/9/26.
//  Copyright © 2019 vine. All rights reserved.
//

#import "NSData+Basic.h"

@implementation NSData (Basic)

- (NSString *)toHexString {
    if (self.length <= 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:self.length];
    
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

+ (instancetype)dataWithHexString:(NSString *)string {
    if (string.length <= 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if (string.length % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < string.length; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [string substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    return hexData;
}

@end
