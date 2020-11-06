//
//  HZRecorder.h
//  Glimpse
//
//  Created by JinTao on 2020/7/1.
//  Copyright © 2020 Wess Cope. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CVPixelBuffer)

- (CVPixelBufferRef)CVPixelBufferRef;

@end


@interface HZRecorder : NSObject

- (void)startRecordingView:(UIView *)view outputURL:(NSURL *)outputURL;

- (void)stop;

@end

//    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
//    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//    NSString *fullPath = [NSString stringWithFormat:@"%@/%d.mp4", path, (int)timeInterval];
//    NSLog(@"%@", fullPath);
//    NSURL *url = [NSURL fileURLWithPath:fullPath];
//    [self.recorder startRecordingView:self.view outputURL:url];
//
//    UIView *view = [[UIView alloc] initWithFrame:CGRectInset(self.view.bounds, 40.0f, 40.0f)];
//    view.backgroundColor = [UIColor greenColor];
//    view.alpha = 0.0f;
//    [self.view addSubview:view];
//
//    [UIView animateWithDuration:5.0 animations:^{
//        view.alpha = 1.0f;
//    } completion:^(BOOL finished) {
//        [self.recorder stop];
//    }];

NS_ASSUME_NONNULL_END
