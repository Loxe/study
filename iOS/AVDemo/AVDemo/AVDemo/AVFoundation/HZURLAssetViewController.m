//
//  HZURLAssetViewController.m
//  AVDemo
//
//  Created by JinTao on 2020/9/4.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "HZURLAssetViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "AVAssetResourceLoaderTest.h"

@interface HZURLAssetViewController ()
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@property (nonatomic, strong) AVAssetResourceLoaderTest *assetResourceLoaderTest;
@end

@implementation HZURLAssetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    /*//NSURL *url = [NSURL URLWithString:@"http://ivi.bupt.edu.cn/hls/cctv6hd.m3u8"];
     NSURL *url = [NSURL URLWithString:@"http://www.w3school.com.cn/i/movie.mp4"];
     //NSURL *url = [NSURL URLWithString:@"rtmp://58.200.131.2:1935/livetv/cctv10"];// 苹果只支持HLS协议，不支持rtmp协议
     AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
     AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:urlAsset];
     AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
     self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
     [self.view.layer addSublayer:self.playerLayer];
     [player play];*/
    
    /*// 用这个类显示视频，效率很高，但只支持 CMSampleBufferRef
    self.displayLayer = [AVSampleBufferDisplayLayer layer];
    [self.view.layer addSublayer:self.displayLayer];
    [self testAVAssetReader];*/
    
    self.assetResourceLoaderTest = [[AVAssetResourceLoaderTest alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:[self.assetResourceLoaderTest player]];
    [self.view.layer addSublayer:self.playerLayer];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.playerLayer.frame = self.view.bounds;
    self.displayLayer.frame = self.view.bounds;
}

- (void)testAVAssetReader {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"FXSample" withExtension:@"mov"];
    // AVAssetReader 只支持本地文件
    //NSURL *url = [NSURL URLWithString:@"http://ivi.bupt.edu.cn/hls/cctv6hd.m3u8"];
    NSDictionary *options = @{
        AVURLAssetPreferPreciseDurationAndTimingKey : @YES
    };
    AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:url options:options];
    static NSString *tracksString = @"tracks";
    [urlAsset loadValuesAsynchronouslyForKeys:@[tracksString] completionHandler:^{
        //NSLog(@"%@", [NSThread currentThread]);已经在新线程
        NSError *error;
        if ([urlAsset statusOfValueForKey:tracksString error:&error] != AVKeyValueStatusLoaded) {
            return;
        }
        AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:urlAsset error:&error];
        if (error) {
            NSLog(@"%@", error.userInfo);
            return;
        }
        AVAssetTrack *assetTrack = [urlAsset tracksWithMediaType:AVMediaTypeVideo][0];
        NSDictionary *outputSettingsDictionary = @{
            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        };
        AVAssetReaderTrackOutput *assetReaderTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetTrack outputSettings:outputSettingsDictionary];
        if ([assetReader canAddOutput:assetReaderTrackOutput]) {
            [assetReader addOutput:assetReaderTrackOutput];
        }
        if (![assetReader startReading]) {
            NSLog(@"startReading fail");
            return;
        }
        NSLog(@"开始读数据");
        while (YES) {
            CMSampleBufferRef sampleBuffer = [assetReaderTrackOutput copyNextSampleBuffer];
            if (!sampleBuffer) {
                NSLog(@"没有数据了");
                break;
            }
            //NSLog(@"%@", sampleBuffer);
            usleep(30000);
            [self.displayLayer enqueueSampleBuffer:sampleBuffer];
            CFRelease(sampleBuffer);
        }
    }];
}

@end
