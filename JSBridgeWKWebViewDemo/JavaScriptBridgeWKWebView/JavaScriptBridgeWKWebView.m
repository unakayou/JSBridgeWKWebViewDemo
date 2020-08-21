//
//  JavaScriptBridgeWKWebView.m
//  WKWebView_JS_Bridge
//
//  Created by unakayou on 6/17/20.
//  Copyright © 2020 uanakyou. All rights reserved.
//

#import "JavaScriptBridgeWKWebView.h"

static NSString *const messageHandlerLog = @"log";
static NSString *const messageHandlerBridge = @"bridge";

//⚠️ must allow the protocol, otherwise it won't find the protocol function
@interface JavaScriptBridgeProxy : NSProxy <WKScriptMessageHandler>
@property (nonatomic, weak) NSObject <WKScriptMessageHandler>* target;
+ (instancetype)proxyWithTarget:(id)target;
@end

@interface JavaScriptBridgeWKWebView()
@property (nonatomic, strong) NSDictionary * typeContainer;
@property (nonatomic, strong) JavaScriptBridgeProxy * proxy;
@end

@implementation JavaScriptBridgeWKWebView
@synthesize configuration = _configuration;

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    return [super initWithFrame:frame configuration:[self appendWebViewConfiguration:configuration]];
}

- (NSDictionary *)typeContainer {
    if (!_typeContainer) {
        _typeContainer = @{@"Mraid" : [NSNumber numberWithInteger:JavaScriptBridgeWKWebViewType_Mraid],
                           @"VAST"  : [NSNumber numberWithInteger:JavaScriptBridgeWKWebViewType_VAST],
                           @"VPAID" : [NSNumber numberWithInteger:JavaScriptBridgeWKWebViewType_VPAID]};
    }
    return _typeContainer;
}

// append settings to WKWebViewConfiguration
- (WKWebViewConfiguration *)appendWebViewConfiguration:(WKWebViewConfiguration *)configuration {
    if (!configuration) {
        configuration = [[WKWebViewConfiguration alloc] init];
    }
    
    if (!configuration.preferences) {
        configuration.preferences = [[WKPreferences alloc]init];
    }
    configuration.preferences.javaScriptEnabled = YES;
    
    if (!configuration.userContentController) {
        configuration.userContentController = [[WKUserContentController alloc] init];
    }
    [self injectJavaScriptBridgeScriptInto:configuration.userContentController];
    [self injectScalesPageToFitScriptInto:configuration.userContentController];
    return configuration;
}

// inject bridge script
- (void)injectJavaScriptBridgeScriptInto:(WKUserContentController *)userContentController {
    
    NSString * JSFilePath = [[NSBundle mainBundle] pathForResource:@"WKWebViewJavaScriptBridge" ofType:@"js"];
    NSString *javaScriptBridgeScriptString = [NSString stringWithContentsOfFile:JSFilePath
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:nil];
    WKUserScript *javaScriptBridgeScriptScript = [[WKUserScript alloc] initWithSource:javaScriptBridgeScriptString
                                                                        injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                     forMainFrameOnly:YES];
    [userContentController addUserScript:javaScriptBridgeScriptScript];
    
    // proxy no retain cycle
    JavaScriptBridgeProxy *proxy = [JavaScriptBridgeProxy proxyWithTarget:self];
    [userContentController addScriptMessageHandler:proxy name:messageHandlerLog];       // 打印日志
    [userContentController addScriptMessageHandler:proxy name:messageHandlerBridge];    // 逻辑传值
}

// inject UIWebView.scalesPageToFit Script
- (void)injectScalesPageToFitScriptInto:(WKUserContentController *)userContentController {
    NSString *scalesPageToFitScriptString = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width');document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *scalesPageToFitScript = [[WKUserScript alloc] initWithSource:scalesPageToFitScriptString
                                                                 injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                              forMainFrameOnly:YES];
    [userContentController addUserScript:scalesPageToFitScript];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(nonnull WKUserContentController *)userContentController
      didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if ([message.name isEqualToString:@"log"]) {
        if ([self.javaScriptBridgeDelegate respondsToSelector:@selector(webView:didReceiveLog:)]) {
            [self.javaScriptBridgeDelegate webView:self didReceiveLog:message.body];
        }
        return;
    } else if ([message.name isEqualToString:@"bridge"]) {
        NSDictionary * parameter = [NSJSONSerialization JSONObjectWithData:[message.body dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:nil];
        JavaScriptBridgeMessage * message = [JavaScriptBridgeMessage new];
        message.json = parameter;
        message.selecotr = parameter[@"method"];
        message.parameters = parameter[@"parameters"];
        message.callbackFuncNameStr = parameter[@"callback"];
        message.type = [self.typeContainer[parameter[@"namespace"]] integerValue];
        self.webViewType = message.type;
        
        if ([self.javaScriptBridgeDelegate respondsToSelector:@selector(webView:didReceiveJavaScriptMessage:)]) {
            [self.javaScriptBridgeDelegate webView:self didReceiveJavaScriptMessage:message];
        }
    } else {
        NSLog(@"%s - unrecoginzed message", __FUNCTION__);
    }
}

// need remove, because the retain cycle
- (void)dealloc {
    [self.configuration.userContentController removeScriptMessageHandlerForName:messageHandlerLog];
    [self.configuration.userContentController removeScriptMessageHandlerForName:messageHandlerBridge];
}

@end

@implementation JavaScriptBridgeProxy
+ (instancetype)proxyWithTarget:(id)target {
    return [[self alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [self.target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = [invocation selector];
    if ([self.target respondsToSelector:sel]) {
        [invocation invokeWithTarget:self.target];
    }
}

/**
 * 重写几个反射机制方法.
 * 比如判断isKindOfClass.消息转发传递进去的参数是一个NSProxy.
 * 解决办法是这里改,或者消息转发时候把invocation的参数index = 2,修改为NSObject.class
 */
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector];
}

- (BOOL)isKindOfClass:(Class)aClass {
    if ([aClass isKindOfClass:[NSProxy class]])
        return YES;
    return [self.target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    if ([aClass isMemberOfClass:[NSProxy class]])
        return YES;
    return [self.target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [self.target conformsToProtocol:aProtocol];
}

@end

@implementation JavaScriptBridgeMessage

@end
