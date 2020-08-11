//
//  YYDebugManager.h
//  YYDebugManager
//
//  Created by wentian on 2020/8/11.
//  Copyright © 2020 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYDebugManager : NSObject

+ (instancetype)sharedInstance;

- (void)start;

@end

NS_ASSUME_NONNULL_END
