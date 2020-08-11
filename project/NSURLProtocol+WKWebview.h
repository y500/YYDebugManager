//
//  NSURLProtocol+WKWebview.h
//  YYDebugManager
//
//  Created by wentian on 2020/8/12.
//  Copyright © 2020 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol (WKWebview)

+ (void)wk_registerScheme:(NSString *)scheme;
+ (void)wk_unregisterScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
