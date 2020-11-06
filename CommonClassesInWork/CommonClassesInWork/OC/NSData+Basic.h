//
//  NSData+Basic.h
//  CommonClassesInWork
//
//  Created by admin on 2019/9/26.
//  Copyright © 2019 vine. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSData (Basic)

- (NSString *)toHexString;

+ (instancetype)dataWithHexString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
