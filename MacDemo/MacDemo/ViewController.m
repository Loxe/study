//
//  ViewController.m
//  MacDemo
//
//  Created by JinTao on 2020/12/7.
//

#import "ViewController.h"
#import <CoreMediaIO/CMIOHardwareDevice.h>

#pragma mark - CTRunDelegateCallbacks
void RunDelegateDeallocCallback( void* refCon ){
    
}

CGFloat RunDelegateGetAscentCallback( void *refCon ){
    NSString *imageName = (__bridge NSString *)refCon;
    CGFloat height = [NSImage imageNamed:imageName].size.height / 2;
    return height;
}

CGFloat RunDelegateGetDescentCallback(void *refCon){
    NSString *imageName = (__bridge NSString *)refCon;
    CGFloat height = [NSImage imageNamed:imageName].size.height / 2;
    return height;
}

CGFloat RunDelegateGetWidthCallback(void *refCon){
    NSString *imageName = (__bridge NSString *)refCon;
    CGFloat width = [NSImage imageNamed:imageName].size.width;
    return width;
}

@interface ViewController ()
@property (nonatomic, strong) NSImageView *imageView;
@end

#pragma mark -
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[NSImageView alloc] init];
    [self.view addSubview:self.imageView];
    
    //self.imageView.image = [self coreTextWithImage];
    [self createPixelBufferWithTestAnimation];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    
    self.imageView.frame = self.view.bounds;
    self.imageView.image = [self coreTextWithImage];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (NSImage *)coreTextWithImage {
    size_t width = self.imageView.bounds.size.width;
    size_t height = self.imageView.bounds.size.height;
    
    NSImage *nsImage = [[NSImage alloc] initWithSize:CGSizeMake(width, height)];
    [nsImage lockFocus];
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    // =============
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect rect = CGRectMake(0, 0, width, height);
    CGPathAddRect(path, NULL, rect);
    
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:@"海洋生物学家在太平洋里发现了一条与众不同的鲸。一般蓝鲸的“歌唱”频率在十五到二十五赫兹，长须鲸子啊二十赫兹左右，而它的频率在五十二赫兹左右。"];
    //设置字体
    [attString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:24] range:NSMakeRange(0, 5)];
    [attString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:13] range:NSMakeRange(6, 2)];
    [attString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:38] range:NSMakeRange(8, attString.length - 8)];
    
    //设置文字颜色
    [attString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(0, 11)];
    [attString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(11, attString.length - 11)];
    
    // callback里可以配置文字的width ascent descent
    NSString * imageName = @"1";
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.dealloc = RunDelegateDeallocCallback;
    callbacks.getAscent = RunDelegateGetAscentCallback;
    callbacks.getDescent = RunDelegateGetDescentCallback;
    callbacks.getWidth = RunDelegateGetWidthCallback;
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&callbacks, (__bridge void * _Nullable)(imageName));
    
    //空格用于给图片留位置
    NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@" "];
     CFAttributedStringSetAttribute((CFMutableAttributedStringRef)imageAttributedString, CFRangeMake(0, 1), kCTRunDelegateAttributeName, runDelegate);
    CFRelease(runDelegate);
    [imageAttributedString addAttribute:@"imageName" value:imageName range:NSMakeRange(0, 1)];
    [attString insertAttributedString:imageAttributedString atIndex:1];
    
    // 画文字
    // 1 文字生成 CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    // 2 CTFramesetterRef 生成 CTFrameRef
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attString.length), path, NULL);
    //把frame绘制到context里
    CTFrameDraw(frame, context);
    
    // 图片处理, 如果只画文字, 后面的代码用不到
    // 3 CTFrameRef 里有多行
    NSArray * lines = (NSArray *)CTFrameGetLines(frame);
    NSInteger lineCount = lines.count;
    CGPoint lineOrigins[lineCount];
    //拷贝frame的line的原点到数组lineOrigins里，如果第二个参数里的length是0，将会从开始的下标拷贝到最后一个line的原点
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    
    for (int i = 0; i < lineCount; i++) {
        CTLineRef line = (__bridge CTLineRef)lines[i];
        // 4 每个CTLine是由多个CTRun来组成，每个CTRun代表一组显示风格一致的文本。
        NSArray * runs = (__bridge NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < runs.count; j++) {
            CTRunRef run =  (__bridge CTRunRef)runs[j];
            NSDictionary * dic = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[dic objectForKey:(NSString *)kCTRunDelegateAttributeName];
            if (delegate == nil) {
                continue;
            }
            NSString * imageName = [dic objectForKey:@"imageName"];
            NSImage * image = [NSImage imageNamed:imageName];
            // baseline（基线），一条假想的线,一行上的字形都以此线作为上下位置的参考，在这条线的左侧存在一个点叫做基线的原点。
            // ascent（上行高度），从原点到字体中最高（这里的高深都是以基线为参照线的）的字形的顶部的距离，ascent是一个正值。
            // descent（下行高度）， 从原点到字体中最深的字形底部的距离， descent是一个负值（比如一个字体原点到最深的字形的底部的距离为2， 那么descent就为-2）。
            // linegap（行距），linegap也可以称作leading（其实准确点讲应该叫做External leading）。 leading，文档说的很含糊，其实是上一行字符的descent到- 下一行的ascent之间的距离。
            // 所以字体的高度是由三部分组成的：leading + ascent + descent
            CGRect runBounds;
            CGFloat ascent;
            CGFloat descent;
            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            runBounds.size.height = ascent + descent;
            CFIndex index = CTRunGetStringRange(run).location;
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, index, NULL);
            runBounds.origin.x = lineOrigins[i].x + xOffset;
            runBounds.origin.y = lineOrigins[i].y - image.size.height / 2;
            runBounds.size = image.size;
            [image drawInRect:runBounds];
            //CGContextDrawImage(context, runBounds, image.image);
        }
    }
    //底层的Core Foundation对象由于不在ARC的管理下，需要自己维护这些对象的引用计数，最后要释放掉。
    CFRelease(framesetter);
    CFRelease(frame);
    CFRelease(path);
    
    //===========
    
    [nsImage unlockFocus];

    return nsImage;
}


- (CVPixelBufferRef)createPixelBufferWithTestAnimation {
    int width = 1280;
    int height = 720;

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);

    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, width, height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, kCGImageAlphaPremultipliedFirst | kCGImageByteOrder32Big);
    NSParameterAssert(context);
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"请插入UVC摄像头" attributes:@{
        NSFontAttributeName : [NSFont systemFontOfSize:36.0f],
        NSForegroundColorAttributeName : [NSColor whiteColor],
    }];
    NSRect bound = [string boundingRectWithSize:NSMakeSize(width, height) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGMutablePathRef path = CGPathCreateMutable();
    //CGRect rect = CGRectMake((width - bound.size.width) / 2, (height - bound.size.height) / 2, bound.size.width, bound.size.height);
    CGRect rect = CGRectMake((width - bound.size.width) / 2, -(height - bound.size.height) / 2, width, height);
    CGPathAddRect(path, NULL, rect);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, string.length), path, NULL);
    CTFrameDraw(frame, context);
    CFRelease(framesetter);
    CFRelease(frame);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    return pxbuffer;
}

@end
