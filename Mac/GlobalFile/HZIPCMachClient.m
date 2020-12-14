//
//  HZIPCMachClient.m
//  MachPortDemo
//
//  Created by JinTao on 2020/12/14.
//

#import "HZIPCMachClient.h"
#import "HZIPCGLobalHeader.h"

@interface HZIPCMachClient () <NSPortDelegate>
@property (nonatomic, strong) NSPort *receivePort;
@end

@implementation HZIPCMachClient

- (void)dealloc {
    NSLog(@"%s", __func__);
    self.receivePort.delegate = nil;
}

- (NSPort *)serverPort {
    // See note in MachServer.mm and don't judge me
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSMachBootstrapServer sharedInstance] portForName:HZMachBootstrapPortName];
    #pragma clang diagnostic pop
}

- (BOOL)isServerAvailable {
    return [self serverPort] != nil;
}

- (NSPort *)receivePort {
    if (_receivePort == nil) {
        NSPort *receivePort = [NSMachPort port];
        _receivePort = receivePort;
        _receivePort.delegate = self;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addPort:receivePort forMode:NSDefaultRunLoopMode];
            // weakSelf should become nil when this object gets destroyed
            while(weakSelf) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            }
            NSLog(@"Shutting down receive run loop");
        });
        NSLog(@"Initialized mach port %d for receiving", ((NSMachPort *)_receivePort).machPort);
    }
    return _receivePort;
}

- (BOOL)connectToServer {
    NSLog(@"%s", __func__);

    NSPort *sendPort = [self serverPort];
    if (sendPort == nil) {
        NSLog(@"Unable to connect to server port");
        return NO;
    }

    NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:sendPort receivePort:self.receivePort components:nil];
    message.msgid = HZIPCMachMessageIDConnect;

    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:5.0];
    if (![message sendBeforeDate:timeout]) {
        NSLog(@"sendBeforeDate failed");
        return NO;
    }

    return YES;
}

- (void)handlePortMessage:(NSPortMessage *)message {
    NSLog(@"%s", __func__);
    NSArray *components = message.components;
    switch (message.msgid) {
        case HZIPCMachMessageIDConnect:
            NSLog(@"Received connect response");
            break;
            
        case HZIPCMachMessageIDFrame:
            //NSLog(@"Received frame message");
            if (components.count >= 3) {
                size_t width;
                [components[0] getBytes:&width length:sizeof(width)];
                size_t height;
                [components[1] getBytes:&height length:sizeof(height)];
                NSData *data = components[2];
                if (self.delegate && [self.delegate respondsToSelector:@selector(receivedFrameData:withWidth:height:)]) {
                    [self.delegate receivedFrameData:data withWidth:width height:height];
                }
            }
            break;
            
        case HZIPCMachMessageIDStop:
            NSLog(@"Received stop message");
            [self.delegate receivedStop];
            break;
            
        default:
            NSLog(@"Received unexpected response msgid %u", (unsigned)message.msgid);
            break;
    }
}

@end