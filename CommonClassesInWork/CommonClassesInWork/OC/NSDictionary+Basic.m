//
//  NSDictionary+Basic.m
//  huiduji
//
//  Created by 黄镇 on 2018/10/30.
//  Copyright © 2018年 jiwei. All rights reserved.
//

#import "NSDictionary+Basic.h"

@implementation NSDictionary (Basic)

- (NSString *)description {
    NSArray *allKeys = [self allKeys];
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"{\t\n "];
    for (NSString *key in allKeys) {
        id value= self[key];
        NSString *valueString = valueString = [NSString stringWithFormat:@"%@", value];
        if ([value isKindOfClass:[NSString class]]) {
            valueString = [NSString stringWithFormat:@"\"%@\"", value];
        }
        [str appendFormat:@"\t \"%@\" = %@,\n", key, valueString];
    }
    [str appendString:@"}"];
    
    return str;
}

@end
