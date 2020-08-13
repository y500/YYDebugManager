//
//  YYDebugManager.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/11.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "YYDebugManager.h"
#import "BLWebSocketsServer.h"
#import <GCDWebServer/GCDWebServer.h>
#import "YYDebugLogKit.h"
#import "YYDebugNetworkKit.h"

static int port = 9000;
static NSString *echoProtocol = @"echo-protocol";

@interface YYDebugManager ()

@property (nonatomic, strong) GCDWebServer *webServer;

@end

@implementation YYDebugManager

+ (instancetype)sharedInstance {
    static YYDebugManager *g_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedInstance = [[self alloc] init];
    });
    
    return g_sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)start {
    [self startWebServer];
    [self startEchoServer];
}

- (void)startEchoServer {
    
    [[BLWebSocketsServer sharedInstance] setHandleRequestBlock:^NSData *(NSData *requestData) {
        
        id json = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingFragmentsAllowed error:nil];
        
        NSData *responseData = [NSData data];
        if ([NSJSONSerialization isValidJSONObject:json]) {
            if ([json[@"type"] isEqual:@"control"]) {
                responseData = [@"operate success!" dataUsingEncoding:NSUTF8StringEncoding];
            }
            
            requestData = [NSJSONSerialization dataWithJSONObject:@{@"result":@"operate success!"} options:NSJSONWritingPrettyPrinted error:nil];
        } else {
            responseData = [NSJSONSerialization dataWithJSONObject:@{@"result":@"invalid command!!!"} options:NSJSONWritingPrettyPrinted error:nil];
        }
        
        return requestData;
    }];
    
    if (![BLWebSocketsServer sharedInstance].isRunning) {
        [[BLWebSocketsServer sharedInstance] startListeningOnPort:port withProtocolName:echoProtocol andCompletionBlock:^(NSError *error) {
            [self startMonitor];
        }];
    }
}

- (void)stopEchoServer {
    if ([BLWebSocketsServer sharedInstance].isRunning) {
        [[BLWebSocketsServer sharedInstance] stopWithCompletionBlock:^ {
            NSLog(@"Server stopped");
        }];
    }
}

- (void)startWebServer {
    _webServer = [[GCDWebServer alloc] init];
    
    NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Web" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
    [_webServer addGETHandlerForBasePath:@"/" directoryPath:[bundle resourcePath] indexFilename:@"index.html" cacheAge:0 allowRangeRequests:YES];
    
    [_webServer startWithPort:9001 bonjourName:nil];
}

- (void)startMonitor {
    [[YYDebugLogKit sharedInstance] startNSLogMonitor];
    [[YYDebugNetworkKit sharedInstance] setupNetworkInterceptor];
}

@end
