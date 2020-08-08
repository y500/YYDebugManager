//
//  YYDebugLogKit.h
//  YYDebugManager
//
//  Created by wentian on 2020/8/3.
//  Copyright © 2020 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYDebugLogKit : NSObject

+ (instancetype)sharedInstance;
- (void)startNSLogMonitor;

@end

NS_ASSUME_NONNULL_END
