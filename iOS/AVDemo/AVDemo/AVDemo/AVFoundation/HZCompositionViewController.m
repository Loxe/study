//
//  HZCompositionViewController.m
//  AVDemo
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

#pragma mark - 音频合成
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
    
    //[compositionTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:track2 atTime:kCMTimeZero error:&error3];
    
    //[compositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero,asset1.duration) toDuration:CMTimeMake(asset1.duration.value, timescale1*3)];//通过此方法可以实现语音或视频的加速和减速
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

// 视频处理
- (void)videoCut:(NSString *)path {
    //    1.
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack  *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;
    
    NSArray *tracks = asset.tracks;
    NSLog(@"所有轨道:%@\n",tracks);//打印出所有的资源轨道
    [compositionTrack setPreferredTransform:[[asset tracksWithMediaType:AVMediaTypeVideo].firstObject preferredTransform]];
    [compositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMake(1, 1), CMTimeMake(5, 1)) ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:kCMTimeZero error:&error];//设置视频的截取范围
    
    //    2.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
    //    CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(compositionTrack.naturalSize.height,0.0);
    //    [videolayerInstruction setTransform:CGAffineTransformRotate(translateToCenter, M_PI_2) atTime:CMTimeMake(2, 1)];//将视频旋转90度
    [videolayerInstruction setOpacity:0.0 atTime:compositionTrack.asset.duration];
    
    //    3.
    AVMutableVideoCompositionInstruction *videoCompositionInstrution = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstrution.timeRange = CMTimeRangeMake(kCMTimeZero, compositionTrack.asset.duration);
    videoCompositionInstrution.layerInstructions = @[videolayerInstruction];
    
    //    4.
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize =  CGSizeMake(compositionTrack.naturalSize.width, compositionTrack.naturalSize.height);//视频宽高，必须设置，否则会奔溃
    /*
     电影：24
     PAL（帕尔制，电视广播制式）和SEACM（）：25
     NTSC（美国电视标准委员会）：29.97
     Web/CD-ROM：15
     其他视频类型，非丢帧视频，E-D动画 30
     */
    videoComposition.frameDuration = CMTimeMake(1, 43);//必须设置，否则会奔溃，一般30就够了
    //    videoComposition.renderScale
    videoComposition.instructions = [NSArray arrayWithObject:videoCompositionInstrution];
    
    /*添加水印*/
    [self addWaterMark:compositionTrack.naturalSize withBlock:^(CALayer *parent, CALayer *videoLayer) {
        videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parent];
    }];
    
    //    5.
    AVAssetExportSession *exportSesstion = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSesstion.outputURL = [NSURL fileURLWithPath:@""];
    exportSesstion.outputFileType = AVFileTypeMPEG4;
    exportSesstion.shouldOptimizeForNetworkUse = YES;
    
    exportSesstion.videoComposition = videoComposition;//设置导出视频的处理方案
    
    [exportSesstion exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = exportSesstion.status;
        if (status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"导出成功");
        }else{
            NSLog(@"导出失败%@",exportSesstion.error);
        }
    }];
}

- (void)addWaterMark:(CGSize)sizeOfVideo withBlock:(void (^)(CALayer *parent,CALayer *videoLayer)) returnBlock{
    
    CATextLayer *textOfvideo=[[CATextLayer alloc] init];
    textOfvideo.string=[NSString stringWithFormat:@"%@", @"测试水印文字"];
    textOfvideo.font = (__bridge CFTypeRef _Nullable)([UIFont boldSystemFontOfSize:24]);
    // 渲染分辨率，否则显示模糊
    textOfvideo.contentsScale = [UIScreen mainScreen].scale;
    [textOfvideo setFrame:CGRectMake(0, 10, sizeOfVideo.width, 40)];
    [textOfvideo setAlignmentMode:kCAAlignmentCenter];
    [textOfvideo setForegroundColor:[UIColor whiteColor].CGColor];
    
    UIImage *myImage=[UIImage imageNamed:@""];
    CALayer *layerCa = [CALayer layer];
    layerCa.contents = (id)myImage.CGImage;
    layerCa.frame = CGRectMake(sizeOfVideo.width-120, sizeOfVideo.height-120, 120, 120);
    layerCa.opacity = 1.0;
    
    CALayer *parentLayer=[CALayer layer];
    CALayer *videoLayer=[CALayer layer];
    parentLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    videoLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:layerCa];
    [parentLayer addSublayer:textOfvideo];
    returnBlock(parentLayer,videoLayer);
}

@end
