//
//  AVAssetResourceLoaderTest.m
//  AVDemo
//
//  Created by JinTao on 2020/9/5.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "AVAssetResourceLoaderTest.h"
#import <MobileCoreServices/MobileCoreServices.h>


@interface AVAssetResourceLoaderTest () <AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *pendingRequests;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask * task;
@property (nonatomic, assign) NSUInteger requestOffset;
@property (nonatomic, assign) NSUInteger downLoadingOffset;
@property (nonatomic, assign) NSUInteger fileLength;
@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSFileHandle *fileHandle;

@end

@implementation AVAssetResourceLoaderTest

- (instancetype)init {
    if (self = [super init]) {
        _pendingRequests = [NSMutableArray array];
        
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        _videoPath = [document stringByAppendingPathComponent:@"temp.mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_videoPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_videoPath error:nil];
            [[NSFileManager defaultManager] createFileAtPath:_videoPath contents:nil attributes:nil];
            
        } else {
            [[NSFileManager defaultManager] createFileAtPath:_videoPath contents:nil attributes:nil];
        }
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_videoPath];
        
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (AVPlayer *)player {
    self.url = [NSURL URLWithString:@"http://www.w3school.com.cn/i/movie.mp4"];
    // 把url的 http:// 转化为 streaming:// 不转化，不会进入 AVAssetResourceLoader 的代理方法，让我们处理下载数据，AVURLAsset直接下载数据了，我们看不到数据
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:self.url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    NSURL *streamingURL = [components URL];
    //streamingURL = self.url;
    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:streamingURL options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    [player play];
    return player;
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"WaitingLoadingRequest < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    [self dealWithLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"CancelLoadingRequest  < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    [self removeLoadingRequest:loadingRequest];
}

#pragma mark - 处理LoadingRequest
- (void)dealWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests addObject:loadingRequest];
    
    NSRange range = NSMakeRange((NSUInteger)loadingRequest.dataRequest.currentOffset, NSUIntegerMax);
    if (self.downLoadingOffset > 0) {
        [self processPendingRequests];
    }
    if (self.task) {
        // 如果新的rang的起始位置比当前缓存的位置还大300k，则重新按照range请求数据
        if (self.requestOffset + self.downLoadingOffset + 1024 * 300 < range.location ||
            range.location < self.requestOffset) {// 如果往回拖也重新请求
            
            [self.task cancel];
            self.task = nil;
            
            [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:nil];
            [[NSFileManager defaultManager] createFileAtPath:self.videoPath contents:nil attributes:nil];
            [self setOffset:range.location];
        }
    } else {
        [self setOffset:0];
    }
}

- (void)setOffset:(NSUInteger)offset {
    self.requestOffset = offset;
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    if (self.requestOffset > 0 && self.fileLength > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.requestOffset, self.fileLength - 1] forHTTPHeaderField:@"Range"];
    }
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests removeObject:loadingRequest];
}

- (void)processPendingRequests {
    NSMutableArray *requestsCompleted = [NSMutableArray array];  //请求完成的数组
    //每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
        [self fillInContentInformation:loadingRequest.contentInformationRequest]; //对每次请求加上长度，文件类型等信息
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest]; //判断此次请求的数据是否处理完全
        if (didRespondCompletely) {
            [requestsCompleted addObject:loadingRequest];  //如果完整，把此次请求放进 请求完成的数组
            [loadingRequest finishLoading];
        }
    }
    [self.pendingRequests removeObjectsInArray:requestsCompleted];   //在所有请求的数组中移除已经完成的
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest {
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(@"video/mp4"), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.fileLength;
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest {
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0) {
        startOffset = dataRequest.currentOffset;
    }
    
    if ((self.requestOffset + self.downLoadingOffset) < startOffset) {
        //NSLog(@"NO DATA FOR REQUEST");
        return NO;
    }
    
    if (startOffset < self.requestOffset) {
        return NO;
    }
    
    NSData *filedata = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_videoPath] options:NSDataReadingMappedIfSafe error:nil];
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = self.downLoadingOffset - ((NSInteger)startOffset - self.requestOffset);
    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    NSRange subDataRange = NSMakeRange((NSUInteger)startOffset- self.requestOffset, (NSUInteger)numberOfBytesToRespondWith);
    if (filedata.length >= subDataRange.location + subDataRange.length) {
        NSData *subData = [filedata subdataWithRange:subDataRange];
        [dataRequest respondWithData:subData];
        NSLog(@"subData:%lu", (unsigned long)subData.length);
    }
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = (self.requestOffset + self.downLoadingOffset) >= endOffset;

    return didRespondFully;
}

#pragma mark - NSURLSessionDataDelegate
//服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    //NSLog(@"response: %@", response);
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString * fileLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    self.fileLength = fileLength.integerValue > 0 ? fileLength.integerValue : response.expectedContentLength;
    NSLog(@"fileLength: %lu", (unsigned long)self.fileLength);
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"didReceiveData %lu", (unsigned long)data.length);
    
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    self.downLoadingOffset += data.length;
    
    [self processPendingRequests];
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"%@", error.userInfo);
    } else {
        NSLog(@"完成");
    }
}

@end
