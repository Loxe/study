//
//  HZFFmpegManager.h
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/18.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZSampleBufferDisplayLayer.h"
#import "HZMTKView.h"

NS_ASSUME_NONNULL_BEGIN

// 是否启用Metal渲染
#define FFMPEG_RENDER_METHOD_METAL 1

/// 连接结果
typedef NS_OPTIONS(NSUInteger, HZFFmpegFinishResult) {
    HZFFmpegFinishResultNoResult = 0, ///< 没结果
    HZFFmpegFinishResultShouldReplay = 1 << 0, ///< 要重连
    HZFFmpegFinishResultEndOfFile = 1 << 1, ///< 文件读完了
    HZFFmpegFinishResultConnectionProblem = 1 << 2, ///< 连接问题
    HZFFmpegFinishResultUserStoped = 1 << 3, ///< 用户停止
};

typedef NS_ENUM(NSUInteger, HZFFmpegPlayState) {
    HZFFmpegPlayStateStoped,
    HZFFmpegPlayStateLoading,
    HZFFmpegPlayStatePlaying,
};

@class HZFFmpegManager;
@protocol HZFFmpegManagerDelegate <NSObject>
@optional
- (void)backTuoLuoyi:(NSInteger)tuoluoyi type:(NSInteger)showtype;
- (void)player:(HZFFmpegManager *)player didReceiveRtcpSrData:(NSData *)data;
- (void)moviePlayBackDidFinish:(HZFFmpegFinishResult)result;
- (void)moviePlayStartPlay;
@end


/// ffmpeg(fast forward moving picture expert group)
@interface HZFFmpegManager : NSObject
@property (nonatomic, readonly) HZFFmpegPlayState playState;
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) BOOL useTcp;
@property (nonatomic, assign) BOOL useVideoToolboxToDecode;
#if FFMPEG_RENDER_METHOD_METAL
@property (nonatomic, strong) HZMTKView *displayLayer;
#else
@property (nonatomic, strong) HZSampleBufferDisplayLayer *displayLayer;
#endif
@property (nonatomic, weak) id<HZFFmpegManagerDelegate> delegate;
- (void)playInNewThreadWithFilePath:(NSString *)filePath;
- (void)stop;
- (void)screenShotWithFilePath:(NSString *)filePath withCompletionHandler:(void (^)(UIImage * _Nullable image))completionHandler;
- (void)startRecordWithFilePath:(NSString *)filePath;
- (void)stopRecord;
@end

NS_ASSUME_NONNULL_END
