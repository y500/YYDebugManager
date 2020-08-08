//
//  YYDebugURLSessionTaskManager.h
//  YYDebugManager
//
//  Created by wentian on 2020/8/8.
//  Copyright © 2020 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYDebugURLSessionTaskManager : NSObject

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration * _Nullable)configuration;

@property (atomic, copy,   readonly ) NSURLSessionConfiguration *configuration;

@property (atomic, strong, readonly ) NSURLSession *session;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes;

@end

NS_ASSUME_NONNULL_END
