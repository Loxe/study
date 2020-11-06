//
//  NSArray+Basic.m
//  huiduji
//
//  Created by 黄镇 on 2018/10/30.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import "NSArray+Basic.h"

@implementation NSArray (Basic)

- (NSString *)description {
    NSMutableString *str = [NSMutableString stringWithFormat:@"%lu (\n", (unsigned long)self.count];
    
    for (id obj in self) {
        [str appendFormat:@"\t%@, \n", obj];
    }
    
    [str appendString:@")"];
    
    return str;
}

@end
