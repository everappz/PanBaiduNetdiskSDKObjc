//
//  PanBaiduAppAuthManager.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "PanBaiduAppAuthManager.h"
#import "PanBaiduAppAuthProvider.h"
#import "PanBaiduNetdiskAPIClient.h"
#import "PanBaiduNetdiskConstants.h"
#import "NSError+PanBaiduNetdisk.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "PanBaiduAppAuthFlow.h"

@interface PanBaiduAppAuthManager()

@property(nonatomic, copy) NSString *clientID;
@property(nonatomic, copy) NSString *clientSecret;
@property(nonatomic, copy) NSString *redirectURI;
@property(nonatomic, copy) NSArray<NSString *> *scopes;
@property(nonatomic, strong) PanBaiduAppAuthFlow *currentAuthorizationFlow;

@end


static PanBaiduAppAuthManager *_sharedAuthManager = nil;

@implementation PanBaiduAppAuthManager

+ (instancetype)sharedManager{
    NSParameterAssert(_sharedAuthManager!=nil);
    return _sharedAuthManager;
}

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI{
    _sharedAuthManager = [[PanBaiduAppAuthManager alloc] initWithClientID:clientID
                                                        clientSecret:clientSecret
                                                         redirectURI:redirectURI
                                                              scopes:[PanBaiduAppAuthManager defaultScopes]];
}

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         redirectURI:(NSString *)redirectURI
                              scopes:(NSArray<NSString *>*)scopes{
    _sharedAuthManager = [[PanBaiduAppAuthManager alloc] initWithClientID:clientID
                                                        clientSecret:clientSecret
                                                         redirectURI:redirectURI
                                                              scopes:scopes];
}

+ (NSArray<NSString *> *)defaultScopes {
    return @[@"basic",@"netdisk"];
}

- (instancetype)initWithClientID:(NSString *)clientID
                    clientSecret:(NSString *)clientSecret
                     redirectURI:(NSString *)redirectURI
                          scopes:(NSArray<NSString *> *)scopes
{
    NSParameterAssert(clientID);
    NSParameterAssert(clientSecret);
    NSParameterAssert(redirectURI);
    NSParameterAssert(scopes);
    self = [super init];
    if(self){
        self.clientID = clientID;
        self.clientSecret = clientSecret;
        self.redirectURI = redirectURI;
        self.scopes = scopes;
    }
    return self;
}

- (PanBaiduAppAuthFlow *)authFlowWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                                webViewDidStartLoadingBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock)webViewDidStartLoadingBlock
                               webViewDidFinishLoadingBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock)webViewDidFinishLoadingBlock
                               webViewDidFailWithErrorBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorErrorBlock)webViewDidFailWithErrorBlock
                                            completionBlock:(PanBaiduNetdiskAppAuthManagerAuthorizationBlock)completionBlock
{
    if (self.currentAuthorizationFlow) {
        [self.currentAuthorizationFlow cancel];
        self.currentAuthorizationFlow = nil;
    }
    
    PanBaiduAppAuthFlow *flow = [PanBaiduAppAuthFlow new];
    flow.clientID = self.clientID;
    flow.clientSecret = self.clientSecret;
    flow.redirectURI = self.redirectURI;
    flow.scopes = self.scopes;
    
    flow.webView = webView;
    flow.webViewDidStartLoadingBlock = webViewDidStartLoadingBlock;
    flow.webViewDidFinishLoadingBlock = webViewDidFinishLoadingBlock;
    flow.webViewDidFailWithErrorBlock = webViewDidFailWithErrorBlock;
    flow.completionBlock = completionBlock;
    
    [flow start];
    self.currentAuthorizationFlow = flow;
    
    return flow;
}

@end

