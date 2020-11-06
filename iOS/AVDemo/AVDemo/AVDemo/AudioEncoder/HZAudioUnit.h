//
//  HZAudioUnit.h
//  AVDemo
//
//  Created by 黄镇 on 2020/9/13.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HZAudioUnit : NSObject

/// audio queue 也能播放能采集，audio unit 可以播，可以采集, 且延迟低
@property (nonatomic, assign) AudioUnit audioUnit;
@property (nonatomic, assign) AudioBufferList bufferList;
@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
