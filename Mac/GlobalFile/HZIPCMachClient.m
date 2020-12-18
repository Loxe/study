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
    HZLog(@"%s", __func__);
    self.receivePort.delegate = nil;
}

- (NSPort *)serverPort {
    // See note in MachServer.mm and don't judge me
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSPort *port = [[NSMachBootstrapServer sharedInstance] portForName:HZMachBootstrapPortName];
    #pragma clang diagnostic pop
    HZLog(@"获取port: %@", port);
    return port;
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
            HZLog(@"Shutting down receive run loop");
        });
        HZLog(@"Initialized mach port %d for receiving", ((NSMachPort *)_receivePort).machPort);
    }
    return _receivePort;
}

- (BOOL)connectToServer {
    HZLog(@"%s", __func__);

    NSPort *sendPort = [self serverPort];
    if (sendPort == nil) {
        HZLog(@"Unable to connect to server port");
        return NO;
    }

    NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:sendPort receivePort:self.receivePort components:nil];
    message.msgid = HZIPCMachMessageIDConnect;

    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:5.0];
    if (![message sendBeforeDate:timeout]) {
        HZLog(@"sendBeforeDate failed");
        return NO;
    }

    return YES;
}

- (BOOL)disconnectToServer {
    HZLog(@"%s", __func__);

    NSPort *sendPort = [self serverPort];
    if (sendPort == nil) {
        HZLog(@"Unable to connect to server port");
        return NO;
    }

    NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:sendPort receivePort:self.receivePort components:nil];
    message.msgid = HZIPCMachMessageIDStop;

    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:5.0];
    if (![message sendBeforeDate:timeout]) {
        HZLog(@"sendBeforeDate failed");
        return NO;
    }

    return YES;
}

- (void)handlePortMessage:(NSPortMessage *)message {
    //HZLog(@"%s", __func__);
    NSArray *components = message.components;
    switch (message.msgid) {
        case HZIPCMachMessageIDConnect:
            HZLog(@"Received connect response");
            break;
            
        case HZIPCMachMessageIDFrame:
            HZLog(@"Received frame message");
            if (components.count >= 4) {
                size_t width;
                [components[0] getBytes:&width length:sizeof(width)];
                size_t height;
                [components[1] getBytes:&height length:sizeof(height)];
                size_t bytesPerRow;
                [components[2] getBytes:&bytesPerRow length:sizeof(bytesPerRow)];
                NSData *data = components[3];
                if (self.delegate && [self.delegate respondsToSelector:@selector(receivedFrameData:withWidth:height:bytesPerRow:)]) {
                    [self.delegate receivedFrameData:data withWidth:width height:height bytesPerRow:bytesPerRow];
                }
            }
            break;
            
        case HZIPCMachMessageIDStop:
            HZLog(@"Received stop message");
            [self.delegate receivedStop];
            break;
            
        default:
            HZLog(@"Received unexpected response msgid %u", (unsigned)message.msgid);
            break;
    }
}

@end
