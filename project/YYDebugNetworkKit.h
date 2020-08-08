//
//  YYDebugNetworkKit.h
//  YYDebugManager
//
//  Created by wentian on 2020/8/4.
//  Copyright © 2020 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYDebugNetworkKit : NSObject

+ (instancetype)sharedInstance;

- (void)setupNetworkInterceptor;

@end

NS_ASSUME_NONNULL_END
