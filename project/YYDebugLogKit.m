//
//  YYDebugLogKit.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/3.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "YYDebugLogKit.h"
#import "fishhook.h"
#import "BLWebSocketsServer.h"
#import "YYDebugMessageCenter.h"

static void (*orig_nslog)(NSString *format, ...);

void my_nslog(NSString *format, ...) {
    va_list vl;
    va_start(vl, format);
    NSString* str = [[NSString alloc] initWithFormat:format arguments:vl];
    va_end(vl);
    orig_nslog(str);
    
    NSString *color = rand()%2 ? @"#333333" : @"#ff0000";
    NSData *data = [[YYDebugMessageCenter sharedInstance] logMessageDataWith:str color:color ];
    orig_nslog(color);
    [[BLWebSocketsServer sharedInstance] pushToAll:data];
}

@implementation YYDebugLogKit

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)startNSLogMonitor {
    struct rebinding nslog_rebinding = {"NSLog",my_nslog,(void*)&orig_nslog};
    rebind_symbols((struct rebinding[1]){nslog_rebinding}, 1);
}

@end
