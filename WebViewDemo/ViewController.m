//
//  ViewController.m
//  WebViewDemo
//
//  Created by ugiant on 2019/10/15.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

////////////////////////////////////////////////////////

@interface WeakWebViewScriptMessageDelegate : NSObject<WKScriptMessageHandler>

//WKScriptMessageHandler 这个协议类专门用来处理JavaScript调用原生OC的方法
@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end

@implementation WeakWebViewScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate {
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

//遵循WKScriptMessageHandler协议，必须实现如下方法，然后把方法向外传递
//通过接收JS传出消息的name进行捕捉的回调方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ([self.scriptDelegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end

////////////////////////////////////////////////////////

@interface ViewController ()<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (strong, nonatomic) WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initWebView];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

//初始化webView
- (void)initWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 创建设置对象
    WKPreferences *preferences = [[WKPreferences alloc]init];
    preferences.javaScriptEnabled = YES;
    config.preferences = preferences;
    
    //自定义的WKScriptMessageHandler 是为了解决内存不释放的问题
    WeakWebViewScriptMessageDelegate *weakScriptMessageDelegate = [[WeakWebViewScriptMessageDelegate alloc] initWithDelegate:self];
    //这个类主要用来做native与JavaScript的交互管理
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    //注册一个name为jsModel的js方法 设置处理接收JS方法的对象
    [wkUController addScriptMessageHandler:weakScriptMessageDelegate name:@"jsCallNative"];
    
    config.userContentController = wkUController;
    
    //注入本地js脚本（使js和native交互方法统一）
    NSString *jsSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ios_brige" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:jsSource injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [config.userContentController addUserScript:script];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) configuration:config];
    [self.view addSubview:self.webView];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.backgroundColor = [UIColor whiteColor];
    
}

#pragma mark ------ WKScriptMessageHandler Delegate -------
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"name:%@---body:%@",message.name,message.body);
    //用message.body获得JS传出的参数体
    NSString * parameter = message.body;
    NSData *jsonData = [parameter dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    
    NSString *method = dic[@"method"];
    NSString *param = dic[@"params"];
    if (param) {
        method = [method stringByAppendingString:@":"];
    }
    SEL sel = NSSelectorFromString(method);
    if ([self respondsToSelector:sel]) {
        [self performSelectorOnMainThread:sel withObject:param waitUntilDone:YES];
    }else{
        NSLog(@"webview not find method %@",method);
    }
}

#pragma mark ------ WKUIDelegate Delegate -------
// 弹框输入回调。
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    NSLog(@"%@---%@",prompt,defaultText);
    NSString *result = @"";
    if ([prompt isEqualToString:@"getSign"]) {
        result = [self getSign];
    }else if ([prompt isEqualToString:@"appendABCwithString"]) {
        result = [self appendABCwithString:defaultText];
    }else if ([prompt isEqualToString:@"isLogin"]) {
        result = [self isLogin]?@"1":@"";
    }
    completionHandler(result);//这里就是要返回给JS的返回值
}

//弹框回调，js的alert不会直接弹出，会回调到此方法，然后由原生弹出
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    [self showAlertWithMessage:message];
    completionHandler();
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark -------- js交互方法 --------

- (void)toLogin {
    [self showAlertWithMessage:@"js调用到了原生无返回，无参数方法"];
}

- (void)setPageTitle:(NSString *)title {
    [self showAlertWithMessage:@"js调用到了原生无返回，有参数方法"];
}

- (NSString *)getSign {
    return @"abcdefghijklmn";
}

- (NSString *)appendABCwithString:(NSString *)string {
    return [NSString stringWithFormat:@"ABC%@",string];
}

- (BOOL)isLogin {
    return YES;
}

@end
