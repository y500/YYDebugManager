//
//  YYDebugMessageCenter.h
//  YYDebugManager
//
//  Created by wentian on 2020/8/7.
//  Copyright © 2020 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYDebugMessageCenter : NSObject

+ (instancetype)sharedInstance;

- (NSDictionary *)logMessageWith:(NSString*)message color:(NSString *)hexColor;
- (NSDictionary *)requestMessageWith:(NSString *)host path:(NSString *)path method:(NSString *)method status:(NSString *)status code:(NSString *)code startDate:(NSString*)startDate duration:(NSString *)duration mimeType:(NSString*)mimeType size:(NSString *)size;

- (NSData *)logMessageDataWith:(NSString*)message color:(NSString*)hexColor;
- (NSData *)requestMessageDataWith:(NSString *)host path:(NSString *)path method:(NSString *)method status:(NSString *)status code:(NSString *)code startDate:(NSString*)startDate duration:(NSString *)duration mimeType:(NSString*)mimeType size:(NSString *)size;

@end

NS_ASSUME_NONNULL_END
