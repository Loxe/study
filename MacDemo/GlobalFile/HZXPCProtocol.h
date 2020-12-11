//
//  HZXPCProtocol.h
//  MacDemo
//
//  Created by JinTao on 2020/12/10.
//

#ifndef HZXPCProtocol_h
#define HZXPCProtocol_h

@protocol HZXPCProtocol
- (void)test:(NSString *)string reply:(void (^)(NSString *))reply;
@end

#endif /* HZXPCProtocol_h */
