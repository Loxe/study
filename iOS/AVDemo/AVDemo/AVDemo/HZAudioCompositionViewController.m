//
//  HZCompositionViewController.m
//  CPDemo
//
//  Created by JinTao on 2020/9/4.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "HZCompositionViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface HZCompositionViewController ()

@end

@implementation HZCompositionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)audioComposition:(UIButton *)button{
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"男声" ofType:@"mp3"];
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"女声" ofType:@"mp3"];
    
    AVURLAsset *asset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path1]];
    AVURLAsset *asset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path2]];
    AVAssetTrack *track1 = [asset1 tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetTrack *track2 = [asset2 tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack  *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    AVMutableCompositionTrack  *compositionTrack1 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];
    
//    AVMutableCompositionTrack  *compositionTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];//这里可以再生成一个mutableCoposition，这样可以实现给一段声音添加一个背景音乐
    
    NSError *error1 = nil;
    NSError *error2 = nil;
    
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset1.duration) ofTrack:track1 atTime:kCMTimeZero error:&error1];
    [compositionTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:track2 atTime:kCMTimeZero error:&error2];

//    [compositionTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:track2 atTime:kCMTimeZero error:&error3];
    
//    [compositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero,asset1.duration) toDuration:CMTimeMake(asset1.duration.value, timescale1*3)];//通过此方法可以实现语音或视频的加速和减速
    AVAssetExportSession *exportSessio = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    exportSessio.outputFileType = AVFileTypeAppleM4A;
    exportSessio.outputURL = [NSURL URLWithString:@""];//路径如果已经存在此文件，则导出会失败
//    exportSessio.timeRange //对音视频截取的时间
    [exportSessio exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = exportSessio.status;
        if (status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"导出成功");
        } else {
          NSLog(@"导出失败");
        }
    }];
}

@end
