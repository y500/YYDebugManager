//
//  YYDebugNetworkKit.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/4.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "YYDebugNetworkKit.h"
#import "YYDebugNSURLProtocol.h"

@implementation YYDebugNetworkKit

+ (instancetype)sharedInstance {
    static YYDebugNetworkKit *g_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedInstance = [[self alloc] init];
    });
    
    return g_sharedInstance;
}

- (void)setupNetworkInterceptor {
    [NSURLProtocol registerClass:[YYDebugNSURLProtocol class]];
}

@end
