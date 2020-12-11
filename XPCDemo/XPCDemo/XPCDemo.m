//
//  XPCDemo.m
//  XPCDemo
//
//  Created by JinTao on 2020/12/10.
//

#import "XPCDemo.h"

@implementation XPCDemo

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
