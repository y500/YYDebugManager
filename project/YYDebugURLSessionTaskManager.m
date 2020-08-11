//
//  YYDebugURLSessionTaskManager.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/8.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "YYDebugURLSessionTaskManager.h"
#import "YYDebugMessageCenter.h"
#import "BLWebSocketsServer.h"

@interface YYDebugURLSessionTask : NSObject

- (instancetype)initWithTask:(NSURLSessionDataTask *)task delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes;

@property (atomic, strong, readonly ) NSURLSessionDataTask *        task;
@property (atomic, strong, readonly ) id<NSURLSessionDataDelegate>  delegate;
@property (atomic, strong, readonly ) NSThread *                    thread;
@property (atomic, copy,   readonly ) NSArray *                     modes;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSURLSessionTaskMetrics *metrics;

//请求返回data
@property (nonatomic, strong) NSMutableData *data;

- (void)performBlock:(dispatch_block_t)block;

- (void)invalidate;

@end

@implementation YYDebugURLSessionTask

- (instancetype)initWithTask:(NSURLSessionDataTask *)task delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes {
    assert(task != nil);
    assert(delegate != nil);
    assert(modes != nil);
    
    self = [super init];
    if (self != nil) {
        self->_task = task;
        self->_delegate = delegate;
        self->_thread = [NSThread currentThread];
        self->_modes = [modes copy];
        
        self.data = [NSMutableData data];
    }
    return self;
}

- (void)performBlock:(dispatch_block_t)block {
    assert(self.delegate != nil);
    assert(self.thread != nil);
    [self performSelector:@selector(performBlockOnClientThread:) onThread:self.thread withObject:[block copy] waitUntilDone:NO modes:self.modes];
}

- (void)performBlockOnClientThread:(dispatch_block_t)block {
    assert([NSThread currentThread] == self.thread);
    block();
}

- (void)invalidate {
    _delegate = nil;
    _thread = nil;
}

@end

@interface YYDebugURLSessionTaskManager () <NSURLSessionDelegate>

@property (atomic, strong, readonly ) NSMutableDictionary *taskInfoByTaskID;
@property (atomic, strong, readonly ) NSOperationQueue *sessionDelegateQueue;

@end

@implementation YYDebugURLSessionTaskManager

+ (instancetype)sharedInstance {
    static YYDebugURLSessionTaskManager *g_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedInstance = [[self alloc] init];
    });
    
    return g_sharedInstance;
}

- (instancetype)init{
    return [self initWithConfiguration:nil];
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration * _Nullable)configuration{
    self = [super init];
    if (self != nil) {
        
        if (configuration == nil) {
            _configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        } else {
            _configuration = [configuration copy];
        }
        
        _taskInfoByTaskID = [[NSMutableDictionary alloc] init];
        
        _sessionDelegateQueue = [[NSOperationQueue alloc] init];
        [_sessionDelegateQueue setMaxConcurrentOperationCount:1];
        [_sessionDelegateQueue setName:@"YYDebugURLSessionDelegateQueue"];
        
        _session = [NSURLSession sessionWithConfiguration:_configuration delegate:self delegateQueue:_sessionDelegateQueue];
        _session.sessionDescription = @"YYDebugURLSessionDelegateQueue";
    }
    return self;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes {
    NSURLSessionDataTask *          task;
    YYDebugURLSessionTask *    taskInfo;
    
    assert(request != nil);
    assert(delegate != nil);
    
    if ([modes count] == 0) {
        modes = @[ NSDefaultRunLoopMode ];
    }
    
    task = [self.session dataTaskWithRequest:request];
    assert(task != nil);
    
    taskInfo = [[YYDebugURLSessionTask alloc] initWithTask:task delegate:delegate modes:modes];
    taskInfo.startDate = [NSDate date];
    
    @synchronized (self) {
        self.taskInfoByTaskID[@(task.taskIdentifier)] = taskInfo;
    }
        
    return task;
}

- (YYDebugURLSessionTask *)taskInfoForTask:(NSURLSessionTask *)task{
    YYDebugURLSessionTask *result;
    
    assert(task != nil);
    
    @synchronized (self) {
        result = self.taskInfoByTaskID[@(task.taskIdentifier)];
        assert(result != nil);
    }
    return result;
}

- (void)sendRequestDataAndStateToServer:(NSURLSessionTask *)task {
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self sendDataWith:task] options:NSJSONWritingFragmentsAllowed error:nil];
    [[BLWebSocketsServer sharedInstance] pushToAll:data];
}

- (NSString *)dateStringWith:(NSDate*)date format:(NSString *)format {
    if (!date) {
        return @"--";
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format ?: @"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

- (NSDictionary*)sendDataWith:(NSURLSessionTask*)task {
    NSURLRequest *request = task.originalRequest;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)task.response;
    
    YYDebugURLSessionTask *taskInfo = [self taskInfoForTask:task];
    
    NSDate *startDate = taskInfo.startDate;
    NSString *dataSize = @"--";
    if (taskInfo.metrics) {
        NSURLSessionTaskTransactionMetrics *transMetric = taskInfo.metrics.transactionMetrics.lastObject;
        startDate = transMetric.requestStartDate;
        dataSize = @(transMetric.countOfResponseBodyBytesReceived).stringValue;
    }
    
    NSString *code = @"--";
    if (httpResponse) {
        code = @(httpResponse.statusCode).stringValue;
    }
    if (taskInfo.error) {
        code = @(taskInfo.error.code).stringValue;
    }
    
    NSArray *fullData = [self fullRequestDataWith:task];
    
    return @{
        @"type": @"network",
        @"taskID": @(task.taskIdentifier).stringValue ?: @"",
        @"host": request.URL.host ?: @"",
        @"path" : request.URL.path ?:@"/",
        @"method": request.HTTPMethod ?:@"",
        @"status": [self httpRequestStateWith:task.state] ?: @"",
        @"code" : code,
        @"startDate" : [self dateStringWith:startDate format:@"yyyy-MM-dd HH:mm:ss"] ?: @"",
        @"duration" : [NSString stringWithFormat:@"%@ms", @((int)(taskInfo.metrics.taskInterval.duration * 1000)).stringValue] ?: @"",
        @"mimeType" : httpResponse.MIMEType ?: @"--",
        @"size" : dataSize ?: @"",
        @"fullData" : fullData ?: @[]
    };
}

- (NSArray*)fullRequestDataWith:(NSURLSessionTask*)task {
    
    NSURLRequest *request = task.originalRequest;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)task.response;
    
    YYDebugURLSessionTask *taskInfo = [self taskInfoForTask:task];
    
    
    NSURLSessionTaskTransactionMetrics *transMetric = nil;
    if (taskInfo.metrics) {
        transMetric = taskInfo.metrics.transactionMetrics.lastObject;
    }
    
    NSDictionary *resHeader = httpResponse.allHeaderFields;
    
    
    NSArray *overviewInfo = @[
        @{@"URL" : request.URL.absoluteString ?: @""},
        @{@"Status" : [self httpRequestStateWith:task.state] ?: @""},
        @{@"Response Code" : @(httpResponse.statusCode).stringValue ?: @"--"},
        @{@"Protocol" : transMetric.networkProtocolName ?: @""},
        @{@"SSL" : [NSString stringWithFormat:@"%@ %@", transMetric.negotiatedTLSProtocolVersion.stringValue, transMetric.negotiatedTLSCipherSuite]},
        @{@"Method" : request.HTTPMethod ?:@""},
        @{@"Kept Alive" : [resHeader[@"Connection"] isEqualToString:@"keep-alive"] ? @"YES" : @"NO"},
        @{@"Content-Type" : resHeader[@"Content-Length"] ?: @""},
        @{@"Client Address" : transMetric.localAddress ?: @""},
        @{@"Remote Address" : transMetric.remoteAddress ?: @""},
        @{@"Timing": @[
                @{@"Request Start Time" : [self dateStringWith:transMetric.requestStartDate format:@"yyyy-MM-dd HH:mm:ss"]},
                @{@"Request End Time" : [self dateStringWith:transMetric.requestEndDate format:@"yyyy-MM-dd HH:mm:ss"]},
                @{@"Response Start Time" : [self dateStringWith:transMetric.responseStartDate format:@"yyyy-MM-dd HH:mm:ss"]},
                @{@"Response End Time" : [self dateStringWith:transMetric.responseEndDate format:@"yyyy-MM-dd HH:mm:ss"]},
                @{@"Duration" : @(taskInfo.metrics.taskInterval.duration).stringValue},
                @{@"DNS Lookup Start Time" : [self dateStringWith:transMetric.domainLookupStartDate format:@"yyyy-MM-dd HH:mm:ss"]},
                @{@"DNS Lookup End Time" : [self dateStringWith:transMetric.domainLookupEndDate format:@"yyyy-MM-dd HH:mm:ss"]},
        ]},
        @{@"Size" : @[
                @{@"Request Header" : @(transMetric.countOfRequestHeaderBytesSent).stringValue},
                @{@"Response Header" : @(transMetric.countOfResponseHeaderBytesReceived).stringValue},
                @{@"Request Body" : @(transMetric.countOfRequestBodyBytesSent).stringValue},
                @{@"Response Body" : @(transMetric.countOfResponseBodyBytesReceived).stringValue},
        ]}
    ];
    
    
    //请求头信息
    NSMutableArray *requestInfo = [NSMutableArray arrayWithCapacity:10];
    for (NSString *key in request.allHTTPHeaderFields.allKeys) {
        [requestInfo addObject:@{key : request.allHTTPHeaderFields[key] ?: @""}];
    }
    
    //请求参数
    NSMutableArray *requestParams = [NSMutableArray arrayWithCapacity:3];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:request.URL.absoluteString];
    [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [requestParams addObject:@{obj.name : obj.value?:@""}];
    }];
    
    //请求包体数据
    NSData *reqData = [self getHttpBodyFromRequest:request];
    NSString *requestBodyString = nil;
    if (reqData) {
        requestBodyString = [self genJsonStringWithData:reqData];
    }
    
    //响应头信息
    NSMutableArray *responseInfo = [NSMutableArray arrayWithCapacity:10];
    for (NSString *key in httpResponse.allHeaderFields.allKeys) {
        [responseInfo addObject:@{key : httpResponse.allHeaderFields[key] ?: @""}];
    }
    
    //响应返回数据
    NSString *jsonString = nil;
    if (task.state == NSURLSessionTaskStateCompleted) {
        NSData *data = taskInfo.data;
        if (data) {
            jsonString = [self genJsonStringWithData:data];
        }
    }
    
    if (jsonString.length == 0) {
        if (taskInfo.error) {
            jsonString = taskInfo.error.description;
        }
    }
        
    NSMutableArray *fullDataList = [NSMutableArray arrayWithCapacity:4];
    if (overviewInfo.count > 0) {
        [fullDataList addObject:@{@"OverView" : overviewInfo}];
    }
    
    if (requestInfo.count > 0) {
        [fullDataList addObject:@{@"Reuqest Headers" : requestInfo}];
    }
    
    if (requestParams.count > 0) {
        [fullDataList addObject:@{@"Request Query" : requestParams}];
    }
    
    if (requestBodyString.length > 0) {
        [fullDataList addObject:@{@"Request Body" : requestBodyString}];
    }
    
    if (responseInfo.count > 0) {
        [fullDataList addObject:@{@"Response Headers": responseInfo}];
    }
    
    if (jsonString) {
        [fullDataList addObject:@{@"Response Data": jsonString}];
    }
    
    return fullDataList;
}

- (NSString*)httpRequestStateWith:(NSURLSessionTaskState)state {
    switch (state) {
        case 0:
            return @"Running";
            break;
        case 1:
            return @"Suspend";
            break;
        case 2:
            return @"Cancel";
            break;
        case 3:
            return @"Complete";
            break;
            
        default:
            break;
    }
    return @"";
}

- (NSString *)genJsonStringWithData:(NSData *)data {
    NSString *jsonString = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
        jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
        // NSJSONSerialization escapes forward slashes. We want pretty json, so run through and unescape the slashes.
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    } else {
        jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (jsonString.length == 0) {
            NSStringEncoding gbEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            jsonString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:gbEncoding];
        }
    }
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser parse];
    
    return jsonString;
}

- (NSData *)getHttpBodyFromRequest:(NSURLRequest *)request{
    NSData *httpBody;
    if (request.HTTPBody) {
        httpBody = request.HTTPBody;
    }else{
        if ([request.HTTPMethod isEqualToString:@"POST"]) {
            if (!request.HTTPBody) {
                uint8_t d[1024] = {0};
                NSInputStream *stream = request.HTTPBodyStream;
                NSMutableData *data = [[NSMutableData alloc] init];
                [stream open];
                while ([stream hasBytesAvailable]) {
                    NSInteger len = [stream read:d maxLength:1024];
                    if (len > 0 && stream.streamError == nil) {
                        [data appendBytes:(void *)d length:len];
                    }
                }
                httpBody = [data copy];
                [stream close];
            }
        }
    }
    return httpBody;
}

#pragma mark -- NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task willPerformHTTPRedirection:response newRequest:newRequest completionHandler:completionHandler];
        }];
    } else {
        completionHandler(newRequest);
    }
    
    [self sendRequestDataAndStateToServer:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:task];
    taskInfo.endDate = [NSDate date];
    
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
        }];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
    
    [self sendRequestDataAndStateToServer:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:needNewBodyStream:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task needNewBodyStream:completionHandler];
        }];
    } else {
        completionHandler(nil);
    }
    
    [self sendRequestDataAndStateToServer:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:task];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
        }];
    }
    
    [self sendRequestDataAndStateToServer:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    YYDebugURLSessionTask *taskInfo;
    taskInfo = [self taskInfoForTask:task];
    taskInfo.error = error;
    
    [self sendRequestDataAndStateToServer:task];
    
    @synchronized (self) {
        [self.taskInfoByTaskID removeObjectForKey:@(taskInfo.task.taskIdentifier)];
    }
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:task didCompleteWithError:error];
            [taskInfo invalidate];
        }];
    } else {
        [taskInfo invalidate];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:dataTask];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
        }];
    } else {
        completionHandler(NSURLSessionResponseAllow);
    }
    
    [self sendRequestDataAndStateToServer:dataTask];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:dataTask];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
        }];
    }
    
    [self sendRequestDataAndStateToServer:dataTask];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:dataTask];
    [taskInfo.data appendData:data];
    
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask didReceiveData:data];
        }];
    }
    
    [self sendRequestDataAndStateToServer:dataTask];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler{
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:dataTask];
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
        }];
    } else {
        completionHandler(proposedResponse);
    }
    
    [self sendRequestDataAndStateToServer:dataTask];
}

#pragma mark ==================== NSURLSessionTaskDelegate ====================
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    
    YYDebugURLSessionTask *taskInfo;
    
    taskInfo = [self taskInfoForTask:dataTask];
    taskInfo.metrics = metrics;
    [self sendRequestDataAndStateToServer:dataTask];
        
    if ([taskInfo.delegate respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]) {
        [taskInfo performBlock:^{
            [taskInfo.delegate URLSession:session task:dataTask didFinishCollectingMetrics:metrics];
        }];
    }
}

@end
