//
//  PanBaiduAppAuthManager.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduAppAuthFlow;

@interface PanBaiduAppAuthManager : NSObject

+ (instancetype)sharedManager;

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                               appID:(NSString *)appID
                         redirectURI:(NSString *)redirectURI;

+ (void)setSharedManagerWithClientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                               appID:(NSString *)appID
                         redirectURI:(NSString *)redirectURI
                              scopes:(NSArray<NSString *> *)scopes;

@property (nonatomic, copy, readonly) NSString *clientID;
@property (nonatomic, copy, readonly) NSString *clientSecret;
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, copy, readonly) NSString *redirectURI;
@property (nonatomic, copy, readonly) NSArray<NSString *> *scopes;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (PanBaiduAppAuthFlow *_Nullable )authFlowWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                                               webViewDidStartLoadingBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock)webViewDidStartLoadingBlock
                                              webViewDidFinishLoadingBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock)webViewDidFinishLoadingBlock
                                              webViewDidFailWithErrorBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorErrorBlock)webViewDidFailWithErrorBlock
                                                           completionBlock:(PanBaiduNetdiskAppAuthManagerAuthorizationBlock)completionBlock;

- (PanBaiduAppAuthFlow *_Nullable)authFlowWithAutoCodeExchangeFromViewController:(UIViewController *)viewController
                                                                 completionBlock:(PanBaiduNetdiskAppAuthManagerAuthorizationBlock)completionBlock;

+ (NSArray<NSString *> *)defaultScopes;

- (void)handleRedirectURL:(NSURL *)url;

@end


NS_ASSUME_NONNULL_END
