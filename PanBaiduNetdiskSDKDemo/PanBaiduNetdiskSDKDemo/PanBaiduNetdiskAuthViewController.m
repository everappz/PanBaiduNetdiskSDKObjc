//
//  MyCloudHomeAuthViewController.m
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskAuthViewController.h"
#import "PanBaiduNetdiskHelper.h"
#import <WebKit/WebKit.h>
#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>


@interface PanBaiduNetdiskAuthViewController ()

@property (nonatomic,strong) PanBaiduNetdiskAPIClient *apiClient;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,strong) WKWebView *webView;

@end

@implementation PanBaiduNetdiskAuthViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.view.backgroundColor = [UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1.0];
    
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    @try{if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
        theConfiguration.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    }} @catch(NSException *exc){}
    
    //scalesPageToFit script
    NSString *jScript = LS_WEB_VIEW_SCALE_TO_FIT_SCRIPT();
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    theConfiguration.userContentController = wkUController;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:theConfiguration];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = [UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1.0];
    [self.view addSubview:self.webView];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

- (void)start{
    __weak typeof(self) weakSelf = self;
    
    
    [[PanBaiduAppAuthManager sharedManager] authFlowWithAutoCodeExchangeFromWebView:self.webView
                                                        webViewDidStartLoadingBlock:^(WKWebView * _Nonnull webView) {
        [weakSelf.activityIndicator startAnimating];
    }
                                                       webViewDidFinishLoadingBlock:^(WKWebView * _Nonnull webView) {
        [weakSelf.activityIndicator stopAnimating];
    }
                                                       webViewDidFailWithErrorBlock:^(WKWebView * _Nonnull webView, NSError * _Nonnull webViewError) {
        [weakSelf.activityIndicator stopAnimating];
        [weakSelf completeWithError:webViewError];
    }
                                                                    completionBlock:^(PanBaiduNetdiskAuthState * _Nullable authState, NSError * _Nullable error) {
        if (authState) {
            PanBaiduAppAuthProvider *authProvider =
            [[PanBaiduAppAuthProvider alloc] initWithIdentifier:[PanBaiduNetdiskHelper uuidString] state:authState];
            
            weakSelf.apiClient =
            [[PanBaiduNetdiskAPIClient alloc] initWithURLSessionConfiguration:nil authProvider:authProvider];
            
            //delay to avoid 429 error code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.apiClient getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                    if(dictionary){
                        [weakSelf completeWithAuthState:authState userModelDictionary:dictionary];
                    }
                    else{
                        [weakSelf completeWithError:error];
                    }
                }];
            });
        }
        else{
            [weakSelf completeWithError:error];
        }
    }];
    
}

- (void)completeWithError:(NSError *)error{
    if([self.delegate respondsToSelector:@selector(panBaiduNetdiskAuthViewController:didFailWithError:)]){
        [self.delegate panBaiduNetdiskAuthViewController:self didFailWithError:error];
    }
}

- (void)completeWithSuccess:(NSDictionary *)authData{
    if([self.delegate respondsToSelector:@selector(panBaiduNetdiskAuthViewController:didSuccessWithAuth:)]){
        [self.delegate panBaiduNetdiskAuthViewController:self didSuccessWithAuth:authData];
    }
}

- (void)completeWithAuthState:(PanBaiduNetdiskAuthState * _Nullable)authState
          userModelDictionary:(NSDictionary * _Nullable)userModelDictionary
{
    PanBaiduNetdiskUser *user = [[PanBaiduNetdiskUser alloc] initWithDictionary:userModelDictionary];
    NSString *userID = [user userID];
    NSString *userName = [user netdiskName];
    NSParameterAssert(userID);
    NSParameterAssert(userName);
    
    NSMutableDictionary *authResult = [NSMutableDictionary new];
    if (userName) {
        [authResult setObject:userName forKey:PanBaiduNetdiskUserNameKey];
    }
    
    if (userID) {
        [authResult setObject:userID forKey:PanBaiduNetdiskUserIDKey];
    }
    
    if (authState) {
        NSData *authData = [NSKeyedArchiver archivedDataWithRootObject:authState.token
                                                 requiringSecureCoding:YES
                                                                 error:nil];
        NSParameterAssert(authData);
        [authResult setObject:authData?:[NSData data] forKey:PanBaiduNetdiskAccessTokenDataKey];
    }
    [self completeWithSuccess:authResult];
}

@end
