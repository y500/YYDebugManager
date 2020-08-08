//
//  NSObject+NSObject_ivar.h
//  YYDebugManager
//
//  Created by wentian on 2020/8/6.
//  Copyright © 2020 wentian. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (NSObject_ivar)

- (NSString *) qCustomDescription;

@end

NS_ASSUME_NONNULL_END
