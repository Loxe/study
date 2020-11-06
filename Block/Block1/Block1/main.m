//
//  main.m
//  Block1
//
//  Created by admin on 2019/10/9.
//  Copyright © 2019 vine. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>

@interface HZObject : NSObject

@property (nonatomic, copy) NSString *name;

@end

@implementation HZObject

- (void)dealloc {
    //[super dealloc];
    NSLog(@"dealloc %@", self.name);
}

@end


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        __block float a = 145;
        [[HZObject alloc] init].name = @"a";
        __weak HZObject *pppl = [[HZObject alloc] init];
        pppl.name = @"b";
    //[pppl retain];
        NSLog(@"%ld", CFGetRetainCount((__bridge void *)pppl));
//        void(^ablock)(void) = ^{
//            a, pppl;
//        };
//        NSLog(@"%ld", CFGetRetainCount((__bridge void *)pppl));
    }
    sleep(10);
    return 0;
}
