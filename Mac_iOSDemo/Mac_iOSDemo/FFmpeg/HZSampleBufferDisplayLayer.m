//
//  HZSampleBufferDisplayLayer.m
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/28.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "HZSampleBufferDisplayLayer.h"

@implementation HZSampleBufferDisplayLayer

- (void)setShouldMaskToRound:(BOOL)shouldMaskToRound {
    _shouldMaskToRound = shouldMaskToRound;
    
    if (shouldMaskToRound) {
        //self.mask = [CALayer layer];
        self.contentsRect = CGRectMake(0.2, 0.4, 0.4, 0.5);
    }
}

@end
