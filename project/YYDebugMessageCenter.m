//
//  YYDebugMessageCenter.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/7.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "YYDebugMessageCenter.h"

@implementation YYDebugMessageCenter

+ (instancetype)sharedInstance {
    static YYDebugMessageCenter *g_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedInstance = [[self alloc] init];
    });
    
    return g_sharedInstance;
}

- (NSDictionary*)logMessageWith:(NSString *)message color:(NSString *)hexColor {
    return @{
        @"type": @"log",
        @"message": message ?: @"",
        @"color": hexColor ?: @"#333333"
    };
}

- (NSDictionary*)requestMessageWith:(NSString *)host path:(NSString *)path method:(NSString *)method status:(NSString *)status code:(NSString *)code startDate:(NSString *)startDate duration:(NSString *)duration mimeType:(NSString*)mimeType size:(NSString *)size {
    return @{
        @"type": @"network",
        @"host": host ?: @"",
        @"path" : path ?:@"",
        @"method": method ?:@"",
        @"status": status ?: @"",
        @"code" : code ?: @"",
        @"startDate" : startDate ?: @"",
        @"duration" : duration ?: @"",
        @"mimeType" : mimeType ?: @"",
        @"size" : size ?: @""
    };
}

- (NSData *)logMessageDataWith:(NSString*)message color:(NSString*)hexColor {
    NSDictionary *dic = [self logMessageWith:message color:hexColor];
    return [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingWithoutEscapingSlashes error:nil];
}
- (NSData *)requestMessageDataWith:(NSString *)host path:(NSString *)path method:(NSString *)method status:(NSString *)status code:(NSString *)code startDate:(NSString*)startDate duration:(NSString *)duration mimeType:(NSString*)mimeType size:(NSString *)size {
    NSDictionary *dic = [self requestMessageWith:host path:path method:method status:status code:code startDate:startDate duration:duration mimeType:mimeType size:size];
    return [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingWithoutEscapingSlashes error:nil];
}

@end
