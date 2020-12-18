//
//  ViewController.m
//  MachPortDemo
//
//  Created by JinTao on 2020/12/14.
//

#import "ViewController.h"
#import "HZIPCGLobalHeader.h"
#import "HZIPCMachClient.h"


@interface ViewController () <HZIPCMachClientDelegate>
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) HZIPCMachClient *machClient;
@end

@implementation ViewController

- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[NSImageView alloc] init];
    [self.view addSubview:self.imageView];
    
//    self.machClient = [[HZIPCMachClient alloc] init];
//    self.machClient.delegate = self;
//    [self.machClient connectToServer];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self.machClient disconnectToServer];
//    });
}

- (void)viewDidLayout {
    [super viewDidLayout];
    
    self.imageView.frame = self.view.bounds;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - HZIPCMachClientDelegate
- (void)receivedFrameData:(NSData *)frameData withWidth:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow {
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate((void *)(frameData.bytes), width, height, 8, bytesPerRow, rgbColorSpace, kCGImageAlphaPremultipliedFirst | kCGImageByteOrder32Big);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    
    // 直接这样创建会内存泄漏, 不知道什么原因
    //NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(width, height)];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image lockFocus];
    CGContextRef imageContext = [NSGraphicsContext currentContext].CGContext;
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), cgImage);
    CGImageRelease(cgImage);
    [image unlockFocus];
    
    self.imageView.image = image;
}

@end
