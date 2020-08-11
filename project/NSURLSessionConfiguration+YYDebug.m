//
//  NSURLSessionConfiguration+YYDebug.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/12.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "NSURLSessionConfiguration+YYDebug.h"

#import <objc/runtime.h>


@implementation NSURLSessionConfiguration (YYDebug)

+ (void)load{
    [self swizzleMethodWithOriginSel:@selector(defaultSessionConfiguration) swizzledSel:@selector(yyDebug_defaultSessionConfiguration)];
    [self swizzleMethodWithOriginSel:@selector(ephemeralSessionConfiguration) swizzledSel:@selector(yyDebug_ephemeralSessionConfiguration)];
}

+ (NSURLSessionConfiguration *)yyDebug_defaultSessionConfiguration{
    NSURLSessionConfiguration *configuration = [self yyDebug_defaultSessionConfiguration];
    [configuration addYYDebugNSURLProtocol];
    return configuration;
}

+ (NSURLSessionConfiguration *)yyDebug_ephemeralSessionConfiguration{
    NSURLSessionConfiguration *configuration = [self yyDebug_ephemeralSessionConfiguration];
    [configuration addYYDebugNSURLProtocol];
    return configuration;
}

- (void)addYYDebugNSURLProtocol {
    if ([self respondsToSelector:@selector(protocolClasses)]
        && [self respondsToSelector:@selector(setProtocolClasses:)]) {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray: self.protocolClasses];
        Class protoCls = NSClassFromString(@"YYDebugNSURLProtocol");
        if (![urlProtocolClasses containsObject:protoCls]) {
            [urlProtocolClasses insertObject:protoCls atIndex:0];
        }
        self.protocolClasses = urlProtocolClasses;
    }
}

+ (void)swizzleMethodWithOriginSel:(SEL)oriSel
                       swizzledSel:(SEL)swizzledSel {
    
    Class cls = object_getClass(self);
    
    Method originAddObserverMethod = class_getClassMethod(cls, oriSel);
    Method swizzledAddObserverMethod = class_getClassMethod(cls, swizzledSel);
    
    BOOL didAddMethod = class_addMethod(cls, oriSel, method_getImplementation(swizzledAddObserverMethod), method_getTypeEncoding(swizzledAddObserverMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls, swizzledSel, method_getImplementation(originAddObserverMethod), method_getTypeEncoding(originAddObserverMethod));
    } else {
        method_exchangeImplementations(originAddObserverMethod, swizzledAddObserverMethod);
    }
}

@end
