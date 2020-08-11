//
//  NSURLProtocol+WKWebview.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/12.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "NSURLProtocol+WKWebview.h"

Class WK_ContextControllerClass() {
  static Class cls;
  if (!cls) {
    cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
  }
  return cls;
}

SEL WK_RegisterSchemeSelector() {
  return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}

SEL WK_UnregisterSchemeSelector() {
  return NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
}

@implementation NSURLProtocol (WKWebview)

+ (void)wk_registerScheme:(NSString *)scheme {
  Class cls = WK_ContextControllerClass();
  SEL sel = WK_RegisterSchemeSelector();
  if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
  }
}

+ (void)wk_unregisterScheme:(NSString *)scheme {
  Class cls = WK_ContextControllerClass();
  SEL sel = WK_UnregisterSchemeSelector();
  if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
  }
}

@end
