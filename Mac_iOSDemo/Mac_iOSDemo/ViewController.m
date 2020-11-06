//
//  ViewController.m
//  Mac_iOSDemo
//
//  Created by JinTao on 2020/9/16.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "ViewController.h"
#import <MetalKit/MetalKit.h>

#if TARGET_OS_MACCATALYST
#import <OpenGL/gl3.h>
#else
#import <OpenGLES/ES2/gl.h>
#endif

#import "HZFFmpegManager.h"
#import "FFmpegHeader.h"
#import "BuiltinFunction.h"

#import "hw_decode.h"

@interface ViewController () <HZFFmpegManagerDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) HZFFmpegManager *ffmpegManager;
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.ffmpegManager = [[HZFFmpegManager alloc] init];
    self.ffmpegManager.delegate = self;
#if FFMPEG_RENDER_METHOD_METAL
    [self.view addSubview:self.ffmpegManager.displayLayer];
#else
    [self.view.layer addSublayer:self.ffmpegManager.displayLayer];
#endif
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"h265" ofType:@"mkv"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"b" ofType:@"mov"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"513" ofType:@"mp4"];
    // ffmpeg -i 1.mov -strict -2 -s 399x399 2.mp4 // -strict strictness 跟标准的严格性
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"mov"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"5" ofType:@"vep"];
    // ffmpeg -i 2.mp4 -vcodec mjpeg mjpeg.mp4
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"mjpeg" ofType:@"mp4"];
    //NSString *path = @"rtsp://192.168.1.1:7070/webcam"; // 公司设备的rtsp地址 mjpeg
    //NSString *path = @"rtsp://192.168.1.1:554/264_rt/XXX.sd"; // 公司设备的rtsp地址 h264
    //NSString *path = @"udp://192.168.1.1:7070"; // 公司设备的udp地址
    //NSString *path = @"http://ivi.bupt.edu.cn/hls/cctv5phd.m3u8";
    //NSString *path = @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov"; // 基于tcp协议的
    //self.ffmpegManager.useTcp = YES;
    [self.ffmpegManager playInNewThreadWithFilePath:path];
    
    self.imageView = [[UIImageView alloc] init];
    [self.view addSubview:self.imageView];
    //self.imageView.backgroundColor = [UIColor redColor];
    
    //CAShapeLayer *layer = [CAShapeLayer layer];
    //self.imageView.layer.mask = layer;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 顶部bar约为28
    self.ffmpegManager.displayLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    self.imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
    CAShapeLayer *layer = self.imageView.layer.mask;
    layer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    layer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)].CGPath;
    
    //NSLog(@"%s %@", __func__, NSStringFromCGRect(self.ffmpegManager.displayLayer.frame));
}

- (IBAction)buttonDidTouchUpInside:(id)sender {
//    if (self.ffmpegManager.playState == HZFFmpegPlayStatePlaying) {
//        [self.ffmpegManager stop];
//    } else if (self.ffmpegManager.playState == HZFFmpegPlayStateStoped) {
//        [self.ffmpegManager playInNewThreadWithFilePath:self.ffmpegManager.filePath];
//    }
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"mp4"];
//    hw_decode([path UTF8String]);
}

#pragma mark - FFmpegManagerDelegate
- (void)backTuoLuoyi:(NSInteger)tuoluoyi type:(NSInteger)showtype {
    //NSLog(@"陀螺仪: %ld", tuoluoyi);
    //NSLog(@"陀螺仪: %f", angle);
    dispatch_async(dispatch_get_main_queue(), ^{
#if FFMPEG_RENDER_METHOD_METAL
        
#else
        CGFloat angle = tuoluoyi / 180.0f * M_PI;
        self.ffmpegManager.displayLayer.transform = CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
#endif
    });
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
//    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
//    //CGContextRef context = UIGraphicsGetCurrentContext();
//    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
//    UIImage* i = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    self.imageView.image = i;

//#if FFMPEG_RENDER_METHOD_METAL
//    NSDate *date = [NSDate date];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    dateFormatter.dateFormat = @"yyyyMMdd";
//    NSString *dirName = [dateFormatter stringFromDate:date];
//    NSString *ducument = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//    NSString *dirPath = [ducument stringByAppendingPathComponent:dirName];
//    //NSString *dirPath = [[Utilities documentPath] stringByAppendingPathExtension:dirName];
//    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
//        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//    dateFormatter.dateFormat = @"HHmmssS";
//    NSString *fileName = [dateFormatter stringFromDate:date];
////    NSString *filePath = [dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", fileName]];
////    NSLog(@"路径: %@", filePath);
////    [self.ffmpegManager.displayLayer screenShotWithFilePath:filePath];
//
//    NSString *filePath = [dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", fileName]];
//    NSLog(@"路径: %@", filePath);
//    if (self.ffmpegManager.isRecording) {
//        [self.ffmpegManager.displayLayer stopRecord];
//    } else {
//        [self.ffmpegManager.displayLayer startRecordWithFilePath:filePath];
//    }
//#else
//#endif
}
@end

