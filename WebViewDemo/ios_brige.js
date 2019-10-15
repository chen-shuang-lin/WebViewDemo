
//无返回值方法转换
//会将jsCallNative.toLogin()的调用方式，转换成window.webkit.messageHandlers.jsCallNative.postMessage()
function calliOSFunction(namespace, functionName, args, callback) {
    if (!window.webkit.messageHandlers[namespace]) return;
    var wrap = {
        "method": functionName,
        "params": args
    };
    window.webkit.messageHandlers[namespace].postMessage(JSON.stringify(wrap));
}

var jsCallNative = {};

jsCallNative.toLogin = function () {
    calliOSFunction("jsCallNative","toLogin");
}

jsCallNative.setPageTitle = function (title) {
    calliOSFunction("jsCallNative","setPageTitle",title);
}

//有返回值方法转换
//会将jsCallNative.getSign()的调用方式，转换成window.prompt()
jsCallNative.getSign = function () {
    var result = window.prompt("getSign");
    return result;
}

jsCallNative.appendABCwithString = function (str) {
    var result = window.prompt("appendABCwithString",str);
    return result;
}

jsCallNative.isLogin = function () {
    var result = window.prompt("isLogin");
    return result;
}

window["jsCallNative"] = jsCallNative;



