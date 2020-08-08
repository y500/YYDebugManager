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
    
    [self startWebServer];
}

- (void)setupEchoServer {
    [[BLWebSocketsServer sharedInstance] setHandleRequestBlock:^NSData *(NSData *requestData) {
        return requestData;
    }];
}

/* Start/Stop the server */
- (void)toggleServer:(UIButton *)sender {
    sender.enabled = NO;
    /* If the server is running */
    if ([BLWebSocketsServer sharedInstance].isRunning) {
        /* The server is stopped */
        [[BLWebSocketsServer sharedInstance] stopWithCompletionBlock:^ {
            NSLog(@"Server stopped");
            [sender setTitle:@"Start Server" forState:UIControlStateNormal];
            sender.enabled = YES;
        }];
    }
    /* If it is not running */
    else {
        /* The server is started */
        [[BLWebSocketsServer sharedInstance] startListeningOnPort:port withProtocolName:echoProtocol andCompletionBlock:^(NSError *error) {
            NSLog(@"Server started");
            [sender setTitle:@"Stop Server" forState:UIControlStateNormal];
            sender.enabled = YES;
            
            [self logWithPush];
            
            [self performSelector:@selector(networkTest) withObject:nil afterDelay:5];
        }];
    }
}

- (void)startWebServer {
    _webServer = [[GCDWebServer alloc] init];
    
    NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Web" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
    [_webServer addGETHandlerForBasePath:@"/" directoryPath:[bundle resourcePath] indexFilename:@"index.html" cacheAge:0 allowRangeRequests:YES];
    
    [_webServer startWithPort:9001 bonjourName:nil];
}

- (void)logWithPush {
//    for (int i = 0; i < 100; i++) {
//        NSLog(@"nslog is triggered:%d", i);
//        sleep(1);
//    }
}

- (void)networkTest {
    //创建一个网络路径
    NSString *browseUrl = [NSString stringWithFormat:@"https://www.sojson.com/open/api/weather/json.shtml?city=%@", @"北京"];
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

@end
