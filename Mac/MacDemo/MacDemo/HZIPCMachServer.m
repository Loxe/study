//
//  HZIPCMachServer.m
//  MacDemo
//
//  Created by JinTao on 2020/12/14.
//

#import "HZIPCMachServer.h"
#import "HZIPCGLobalHeader.h"

#import <AppKit/AppKit.h>
#import <malloc/malloc.h>


@interface HZIPCMachServer () <NSPortDelegate>
@property (nonatomic, strong) NSPort *port;
@property (nonatomic, strong) NSMutableSet<NSPort *> *clientPorts;
@property (nonatomic, strong) NSRunLoop *runLoop;
@property (nonatomic, strong) NSTimer *dataTimer;
@end


@implementation HZIPCMachServer

- (id)init {
    if (self = [super init]) {
        self.clientPorts = [[NSMutableSet alloc] init];
        [self startSendData];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [self.runLoop removePort:self.port forMode:NSDefaultRunLoopMode];
    [self.port invalidate];
    self.port.delegate = nil;
}

- (void)stop {
    NSLog(@"sending stop message to %lu clients", self.clientPorts.count);
    [self sendMessageToClientsWithMsgId:HZIPCMachMessageIDStop components:nil];
}

- (void)run {
    if (self.port != nil) {
        NSLog(@"mach server already running!");
        return;
    }
    
    // It's a bummer this is deprecated. The replacement, NSXPCConnection, seems to require
    // an assistant process that lives inside the .app bundle. This would be more modern, but adds
    // complexity and I think makes it impossible to just run the `obs` binary from the commandline.
    // So let's stick with NSMachBootstrapServer at least until it fully goes away.
    // At that point we can decide between NSXPCConnection and using the CoreFoundation versions of
    // these APIs (which are, interestingly, not deprecated)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.port = [[NSMachBootstrapServer sharedInstance] servicePortWithName:HZMachBootstrapPortName];
#pragma clang diagnostic pop
    if (self.port == nil) {
        // This probably means another instance is running.∫
        NSLog(@"Unable to open mach server port.");
        return;
    }
    
    self.port.delegate = self;
    
    self.runLoop = [NSRunLoop mainRunLoop];
    [self.runLoop addPort:self.port forMode:NSRunLoopCommonModes];
    
    NSLog(@"Mach server port start run!");
}

#pragma mark - NSPortDelegate
- (void)handlePortMessage:(NSPortMessage *)message {
    switch (message.msgid) {
        case HZIPCMachMessageIDConnect:
            if (message.sendPort != nil) {
                NSLog(@"Mach server received connect message from port %d!", ((NSMachPort *)message.sendPort).machPort);
                [self.clientPorts addObject:message.sendPort];
            }
            break;
            
        case HZIPCMachMessageIDStop:
            if (message.sendPort != nil) {
                NSLog(@"mach server received disconnect message from port %d!", ((NSMachPort *)message.sendPort).machPort);
                if ([self.clientPorts containsObject:message.sendPort]) {
                    [self.clientPorts removeObject:message.sendPort];
                }
            }
            break;
            
        default:
            NSLog(@"Unexpected mach message ID %u", (unsigned)message.msgid);
            break;
    }
}

#pragma mark - Message
- (void)sendMessageToClientsWithMsgId:(uint32_t)msgId components:(nullable NSArray *)components {
    if ([self.clientPorts count] <= 0) {
        return;
    }
    
    NSMutableSet *removedPorts = [NSMutableSet set];
    
    for (NSPort *port in self.clientPorts) {
        @try {
            NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:port receivePort:nil components:components];
            message.msgid = msgId;
            if (![message sendBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
                NSLog(@"failed to send message to %d, removing it from the clients!", ((NSMachPort *)port).machPort);
                
                [removedPorts addObject:port];
            } else {
                NSLog(@"send message");
            }
        } @catch (NSException *exception) {
            NSLog(@"failed to send message (exception) to %d, removing it from the clients! %@", ((NSMachPort *)port).machPort, exception);
            [removedPorts addObject:port];
        }
    }
    
    // Remove dead ports if necessary
    [self.clientPorts minusSet:removedPorts];
}

- (void)sendFrameWithSize:(NSSize)size timestamp:(uint64_t)timestamp fpsNumerator:(uint32_t)fpsNumerator fpsDenominator:(uint32_t)fpsDenominator frameBytes:(uint8_t *)frameBytes {
    if ([self.clientPorts count] <= 0) {
        return;
    }
    
    @autoreleasepool {
        CGFloat width = size.width;
        NSData *widthData = [NSData dataWithBytes:&width length:sizeof(width)];
        CGFloat height = size.height;
        NSData *heightData = [NSData dataWithBytes:&height length:sizeof(height)];
        NSData *timestampData = [NSData dataWithBytes:&timestamp length:sizeof(timestamp)];
        NSData *fpsNumeratorData = [NSData dataWithBytes:&fpsNumerator length:sizeof(fpsNumerator)];
        NSData *fpsDenominatorData = [NSData dataWithBytes:&fpsDenominator length:sizeof(fpsDenominator)];
        
        // NOTE: I'm not totally sure about the safety of dataWithBytesNoCopy in this context.
        // Seems like there could potentially be an issue if the frameBuffer went away before the
        // mach message finished sending. But it seems to be working and avoids a memory copy. Alternately
        // we could do something like
        // NSData *frameData = [NSData dataWithBytes:(void *)frameBytes length:size.width * size.height * 2];
        NSData *frameData = [NSData dataWithBytesNoCopy:(void *)frameBytes length:size.width * size.height * 2 freeWhenDone:NO];
        [self sendMessageToClientsWithMsgId:HZIPCMachMessageIDFrame components:@[widthData, heightData, timestampData, frameData, fpsNumeratorData, fpsDenominatorData]];
    }
}

- (void)sendData:(NSData *)data withWidth:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow {
    if ([self.clientPorts count] <= 0) {
        return;
    }
    
    @autoreleasepool {
        NSData *widthData = [NSData dataWithBytes:&width length:sizeof(width)];
        NSData *heightData = [NSData dataWithBytes:&height length:sizeof(height)];
        NSData *bytesPerRowData = [NSData dataWithBytes:&bytesPerRow length:sizeof(bytesPerRow)];
        [self sendMessageToClientsWithMsgId:HZIPCMachMessageIDFrame components:@[widthData, heightData, bytesPerRowData, data]];
    }
}

#pragma mark - Data
- (void)startSendData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.dataTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(sendData) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.dataTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)sendData {
    //NSLog(@"timer");
    size_t width = 1280;
    size_t height = 720;
    size_t bytesPerRow = 0;
    NSData *data = [self pixDataWithWidth:width height:height bytesPerRow:&bytesPerRow];
    [self sendData:data withWidth:width height:height bytesPerRow:bytesPerRow];
}

- (NSData *)pixDataWithWidth:(size_t)width height:(size_t)height bytesPerRow:(size_t *)bytesPerRow  {
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, rgbColorSpace, kCGImageAlphaPremultipliedFirst | kCGImageByteOrder32Big);
    NSParameterAssert(context);
    
    //反转
    //CGContextTranslateCTM(context, width, 0);
    //CGContextScaleCTM(context, -1.0, 1.0);
    
    // 黑底
    CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    
    CGContextSetFillColorWithColor(context, blackColor);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    
    CFRelease(blackColor);
    
    static int count = 0;
    // 文字
    NSString *s = [NSString stringWithFormat:@"发送的数据: %d", count++];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:s attributes:@{
        NSFontAttributeName : [NSFont systemFontOfSize:36.0f],
        NSForegroundColorAttributeName : [NSColor whiteColor],
    }];
    NSRect bound = [string boundingRectWithSize:NSMakeSize(width, height) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect rect = CGRectMake((width - bound.size.width) / 2, -(height - bound.size.height) / 2, width, height);
    CGPathAddRect(path, NULL, rect);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, string.length), path, NULL);
    CTFrameDraw(frame, context);
    CFRelease(framesetter);
    CFRelease(frame);
    
    void *data = CGBitmapContextGetData(context);
    *bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    NSData *nsData = [[NSData alloc] initWithBytes:data length:*bytesPerRow * height];
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    return nsData;
}

@end

