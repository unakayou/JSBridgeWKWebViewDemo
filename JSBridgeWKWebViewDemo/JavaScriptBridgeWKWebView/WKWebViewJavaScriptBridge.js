//
//  WKWebView_JS_Bridge.js
//
//  Created by unakayou on 6/15/20.
//  Copyright © 2020 unakayou. All rights reserved.
//

/**
 * iOS bridge           JS call native
 * @param handlerName   WKWebView.MessageHandler.name
 * @param namespace     Mraid、VAST、VPAID、etc
 * @param funcName      Native function name
 * @param args          Parameters Dictionary
 * @param callback      Native callback JS
 */
function calliOSFunction(handlerName, namespace, funcName, args, callback) {
    if (!window.webkit.messageHandlers[handlerName]) return;
    if (namespace == null || funcName == null) return;
    var json = {};
    json["namespace"] = namespace;
    json["method"] = funcName;
    if (args != null || typeof(args) != "undefined") json["parameters"] = args;
    if (callback != null || typeof(callback) != "undefined") json["callback"] = callback;
    window.webkit.messageHandlers[handlerName].postMessage(JSON.stringify(json));
}

// js call this func
var bridge = window.bridge = {};
bridge.callNative = function(funcName, args, callback) {
    calliOSFunction("bridge", bridge.namespace, funcName, args,callback);
}

// log at two location
console.log = (function(oriLogFunc) {
    return function(str) {
        calliOSFunction("log", console.namespace, "log", str);      // Native log
        oriLogFunc.call(console, console.namespace + ":" + str);    // JS log
    }
})(console.log);
