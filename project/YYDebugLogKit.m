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
#include <sys/_types/_iovec_t.h>

//static void (*orig_NSLog)(NSString *format, ...);
//
//void(new_NSLog)(NSString *format, ...) {
//    va_list args;
//    if(format) {
//        va_start(args, format);
//        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
//        NSData *data = [[YYDebugMessageCenter sharedInstance] logMessageDataWith:message color:@"#333333"];
//        [[BLWebSocketsServer sharedInstance] pushToAll:data];
//        orig_NSLog(@"%@", message);
//        va_end(args);
//    }
//}

static ssize_t (*orig_writev)(int a, const struct iovec * v, int v_len);
ssize_t new_writev(int a, const struct iovec *v, int v_len) {
    NSMutableString *string = [NSMutableString string];
    for (int i = 0; i < v_len; i++) {
        char *c = (char *)v[i].iov_base;
        [string appendString:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]];
    }
    ssize_t result = orig_writev(a, v, v_len);
    NSData *data = [[YYDebugMessageCenter sharedInstance] logMessageDataWith:string color:@"#333333"];
    [[BLWebSocketsServer sharedInstance] pushToAll:data];
    return result;
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
    rebind_symbols((struct rebinding[1]){{"writev", new_writev, (void *)&orig_writev}}, 1);
}

@end
