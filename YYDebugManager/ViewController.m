//
//  ViewController.m
//  YYDebugManager
//
//  Created by wentian on 2020/8/3.
//  Copyright © 2020 wentian. All rights reserved.
//

#import "ViewController.h"
#import "BLWebSocketsServer.h"
#import <GCDWebServer/GCDWebServer.h>

static int port = 9000;
static NSString *echoProtocol = @"echo-protocol";

@interface ViewController ()

@property (nonatomic, strong) GCDWebServer *webServer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(10, 100, self.view.frame.size.width - 20, 60);
    button.layer.borderColor = [UIColor blueColor].CGColor;
    button.layer.borderWidth=1;
    [button addTarget:self action:@selector(toggleServer:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button setTitle:@"start server" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
}

/* Start/Stop the server */
- (void)toggleServer:(UIButton *)sender {
    [self networkTest];
    [self webpageTest];
}

- (void)logWithPush {
    for (int i = 0; i < 100; i++) {
        NSLog(@"nslog is triggered:%d", i);
        sleep(1);
    }
}

- (void)networkTest {
        
    //创建一个网络路径
    NSString *browseUrl = [NSString stringWithFormat:@"https://www.sojson.com/tesssss.mtx%@", @"北京"];
    //处理一下特殊字符汉字等
    browseUrl =  [browseUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    //创建一个网络请求
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:browseUrl]];
    [request setValue:@"auth" forHTTPHeaderField:@"wentian"];
    [request setValue:@"come" forHTTPHeaderField:@"on"];
    //创建一个Task任务：
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data == nil) {
            return ;
        }
         NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingMutableLeaves) error:nil];
        NSLog(@"从服务器获取到数据%@", dict);
    }];
    NSLog(@"sessionDataTask------>%p", sessionDataTask);
    //执行任务
    [sessionDataTask resume];
    
    
    
    
}

- (void)webpageTest {
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://qdddxxq.com"]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }] resume];
        
    return;
    [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://jt.rsscc.com/gtgjxad/adver/advertisementV2.action?pid=2008&uid=2a25d24b180701bce&uuid=PRO-D8F540C0-AAB5-4FAD-A776-D9991ECADECB&idfa=8791B4C3-498A-4706-9082-70541EFC16E7&appopentime=1596521526843&gtgjtime=2020-08-04%2014:12:07&gtgjuid=2a25d24b180701bce&ua=22659518352850944/66457964E6022B5192F3243E71FD8AEE&iscorpuser=1&sid=F04398E9&p=appstorepro,ios,13.4.1,gtgjpro,7.3.7,iPhone12.1,0&hlo_platform=%7B%22source%22%3A%22appstorepro%22%2C%22hbgjVer%22%3A%227.8%22%2C%22gtgjVer%22%3A%227.3.7%22%2C%22linkmode%22%3A%22wifi%22%2C%22linkcode%22%3A%2201%22%2C%22linkmcc%22%3A%22460%22%2C%22agent%22%3A%22Mozilla%5C%2F5.0%20%28iPhone%3B%20CPU%20iPhone%20OS%2013_4_1%20like%20Mac%20OS%20X%29%20AppleWebKit%5C%2F605.1.15%20%28KHTML%2C%20like%20Gecko%29%20Mobile%5C%2F15E148%22%2C%22name%22%3A%22gtgjpro%22%2C%22os%22%3A%22ios%22%2C%22root%22%3A%220%22%2C%22osVer%22%3A%2213.4.1%22%2C%22isPro%22%3A%221%22%2C%22model%22%3A%22iPhone12.1%22%2C%22module%22%3A%22gtgj%22%7D&x=828&y=1792&startapp=1&refmt=json&tmc=0"]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }] resume];
}

@end
