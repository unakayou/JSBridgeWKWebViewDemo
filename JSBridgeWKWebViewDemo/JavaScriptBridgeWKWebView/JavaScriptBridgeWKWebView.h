//
//  JavaScriptBridgeWKWebView.h
//  WKWebView_JS_Bridge
//
//  Created by unakayou on 6/17/20.
//  Copyright © 2020 unakayou. All rights reserved.
//

#import <WebKit/WebKit.h>

@class JavaScriptBridgeWKWebView;

typedef NS_ENUM(NSInteger, JavaScriptBridgeWKWebViewType) {
    JavaScriptBridgeWKWebViewType_Mraid,
    JavaScriptBridgeWKWebViewType_VAST,
    JavaScriptBridgeWKWebViewType_VPAID,
};

NS_ASSUME_NONNULL_BEGIN

@interface JavaScriptBridgeMessage : NSObject
@property (nonatomic, strong) NSDictionary * json;                      // 原始json数据
@property (nonatomic, copy)   NSString * selecotr;                      // JS调用Native方法名
@property (nonatomic, strong) NSDictionary * parameters;                // 传递参数
@property (nonatomic, copy)   NSString * callbackFuncNameStr;           // Native回调JS方法名
@property (nonatomic, assign) JavaScriptBridgeWKWebViewType type;       // 广告种类 Mraid、VAST、VPAID
@end

#pragma mark - JavaScriptBridgeWKWebView
@protocol JavaScriptBridgeProtocol <NSObject>
- (void)webView:(JavaScriptBridgeWKWebView *)webView didReceiveLog:(NSString *)logInfo;
- (void)webView:(JavaScriptBridgeWKWebView *)webView didReceiveJavaScriptMessage:(JavaScriptBridgeMessage *)message;
@end

@interface JavaScriptBridgeWKWebView : WKWebView <WKScriptMessageHandler>
@property (nonatomic, assign) JavaScriptBridgeWKWebViewType webViewType;
@property (nonatomic, weak) id <JavaScriptBridgeProtocol> javaScriptBridgeDelegate;
@end

NS_ASSUME_NONNULL_END
