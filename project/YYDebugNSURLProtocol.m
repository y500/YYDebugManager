//
//  YYDebugNSURLProtocol.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/4.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "YYDebugNSURLProtocol.h"
#import "BLWebSocketsServer.h"
#import <objc/runtime.h>
#import "YYDebugMessageCenter.h"
#import "YYDebugURLSessionTaskManager.h"

static NSString * const kYYDebugProtocolKey = @"YYDebugProtocolKey";

@interface YYDebugNSURLProtocol () <NSURLConnectionDelegate,NSURLConnectionDataDelegate, NSURLSessionDataDelegate>

@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSURLSessionConfiguration *configuration;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionDelegateQueue;
@property (nonatomic, strong) NSURLSessionTask *task;

@property (atomic, strong, readwrite) NSThread *clientThread;
@property (atomic, copy) NSArray *modes;

@end

@implementation YYDebugNSURLProtocol

+ (YYDebugURLSessionTaskManager*)sharedTaskManager {
    static YYDebugURLSessionTaskManager *g_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedInstance = [[YYDebugURLSessionTaskManager alloc] initWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    });
    
    return g_sharedInstance;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:kYYDebugProtocolKey inRequest:request]) {
        return NO;
    }
    
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    //文件类型不作处理
    NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
    if (contentType && [contentType containsString:@"multipart/form-data"]) {
        return NO;
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kYYDebugProtocolKey inRequest:mutableReqeust];
    return [mutableReqeust copy];
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b{
    return [super requestIsCacheEquivalent:a toRequest:b];
}


- (void)startLoading {
    NSURLRequest *recursiveRequest = [[self class] canonicalRequestForRequest:self.request];
    
    NSMutableArray *calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
        
    NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ( (currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
        [calculatedModes addObject:currentMode];
    }
    self.modes = calculatedModes;
    assert([self.modes count] > 0);
    
    recursiveRequest = [[self request] mutableCopy];
    assert(recursiveRequest != nil);
        
    self.clientThread = [NSThread currentThread];
    self.data = [NSMutableData data];
    self.startTime = [[NSDate date] timeIntervalSince1970];
    self.task = [[[self class] sharedTaskManager] dataTaskWithRequest:recursiveRequest delegate:self modes:self.modes];
    assert(self.task != nil);
    
    [self.task resume];
}

- (void)stopLoading {
    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
    }
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.response = response;
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.data appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error) {
        self.error = error;
        [self.client URLProtocol:self didFailWithError:error];
    }else{
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    //判断服务器返回的证书类型, 是否是服务器信任
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //强制信任
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, card);
    }
}


#pragma mark ==================== NSURLSessionTaskDelegate ====================
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    NSLog(@"metrics:%@", metrics.debugDescription);
}

@end

