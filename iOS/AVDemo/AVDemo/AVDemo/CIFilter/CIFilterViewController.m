//
//  CIFilterViewController.m
//  AVDemo
//
//  Created by JinTao on 2020/12/3.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "CIFilterViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CubeMap.h"

@interface CIFilterViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDeviceInput *frontCamera;
@property (strong, nonatomic) AVCaptureDeviceInput *backCamera;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInputDevice;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImage *redImage;
@end

@implementation CIFilterViewController

- (UIImage *)getRedImageWithSize:(CGSize)size {
    if (!_redImage) {
        UIGraphicsBeginImageContext(size);
        CGContextRef c = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(c, [UIColor redColor].CGColor);
        CGContextFillRect(c, CGRectMake(0, 0, size.width, size.height));
        _redImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return _redImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.imageView];
    
    [self initCapture];
}

- (void)initCapture {
    self.captureSession = [[AVCaptureSession alloc] init];
    
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    NSArray *videoDevices = discoverySession.devices;
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    self.videoInputDevice = self.backCamera;
    
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_UNSPECIFIED, 0);
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    [self.captureSession beginConfiguration];
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
    }
    [self.captureSession commitConfiguration];
    dispatch_async(queue, ^{
        [self.captureSession startRunning];
    });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
    struct CubeMap cubeMap = createCubeMap(60, 90);
    NSData *data = [NSData dataWithBytesNoCopy:cubeMap.data length:cubeMap.length freeWhenDone:YES];
    // 把给定的范围的颜色去除, 不是识别物体再去除物体外的背景
    CIFilter *colorCubeFilter = [CIFilter filterWithName:@"CIColorCube"];
    [colorCubeFilter setValue:@(cubeMap.dimension) forKey:@"inputCubeDimension"];
    [colorCubeFilter setValue:data forKey:@"inputCubeData"];
    [colorCubeFilter setValue:ciImage forKey:kCIInputImageKey];
    CIImage *colorCubeImage = colorCubeFilter.outputImage;
    
    CIFilter *sourceOverCompositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [sourceOverCompositingFilter setValue:colorCubeImage forKey:kCIInputImageKey];
    CIImage *redImage = [[CIImage alloc] initWithImage:[self getRedImageWithSize:CGSizeMake(ciImage.extent.size.height, ciImage.extent.size.width)]];
    [sourceOverCompositingFilter setValue:redImage forKey:kCIInputBackgroundImageKey];
    CIImage *outputImage = sourceOverCompositingFilter.outputImage;
//    CIContext *context = [CIContext context];
//    CGImageRef cgImage = [context createCGImage:outputImage fromRect:outputImage.extent];
    UIImage *uiImage = [UIImage imageWithCIImage:outputImage];
    //CFRelease(cgImage);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = uiImage;
    });
}

@end
