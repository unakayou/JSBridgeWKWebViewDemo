//
//  ViewController.m
//  JSBridgeWKWebViewDemo
//
//  Created by unakayou on 8/21/20.
//  Copyright © 2020 uanakyou. All rights reserved.
//

#import "ViewController.h"
#import "MyJavaScriptBridgeWKWebView.h"

@interface ViewController () <WKUIDelegate, WKNavigationDelegate, JavaScriptBridgeProtocol>
@property (nonatomic, strong) MyJavaScriptBridgeWKWebView * wkWebView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.wkWebView = [[MyJavaScriptBridgeWKWebView alloc] init];
    self.wkWebView.UIDelegate = self;
    self.wkWebView.navigationDelegate = self;
    self.wkWebView.javaScriptBridgeDelegate = self;
    [self.view addSubview:self.wkWebView];
    
    NSString *testHtmlPath = [[NSBundle mainBundle] pathForResource:@"JavaScriptBridgeTest" ofType:@"html"];
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:testHtmlPath]]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.wkWebView.frame = self.view.frame;
}

- (void)webView:(nonnull JavaScriptBridgeWKWebView *)webView didReceiveJavaScriptMessage:(nonnull JavaScriptBridgeMessage *)message {
    NSLog(@"Logging - account:%@",message.parameters[@"account"]);
    sleep(2);
    if (message.callbackFuncNameStr) {
        NSLog(@"Login success - call JS function:%@()", message.callbackFuncNameStr);
        NSString *callbackString = [NSString stringWithFormat:@"%@(true)",message.callbackFuncNameStr];
        [webView evaluateJavaScript:callbackString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"JS returen: %@",result);
        }];
    }
}

- (void)webView:(nonnull JavaScriptBridgeWKWebView *)webView didReceiveLog:(nonnull NSString *)logInfo {
    NSLog(@"console.log:%@", logInfo);
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
}

@end
