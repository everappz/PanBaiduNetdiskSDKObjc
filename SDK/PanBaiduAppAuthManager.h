//
//  PanBaiduAppAuthManager.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
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

@property(nonatomic, copy, readonly) NSString *clientID;
@property(nonatomic, copy, readonly) NSString *clientSecret;
@property(nonatomic, copy, readonly) NSString *appID;
@property(nonatomic, copy, readonly) NSString *redirectURI;
@property(nonatomic, copy, readonly) NSArray<NSString *> *scopes;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (PanBaiduAppAuthFlow *_Nullable )authFlowWithAutoCodeExchangeFromWebView:(WKWebView *)webView
                                               webViewDidStartLoadingBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock)webViewDidStartLoadingBlock
                                              webViewDidFinishLoadingBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock)webViewDidFinishLoadingBlock
                                              webViewDidFailWithErrorBlock:(PanBaiduNetdiskAuthorizationWebViewCoordinatorErrorBlock)webViewDidFailWithErrorBlock
                                                           completionBlock:(PanBaiduNetdiskAppAuthManagerAuthorizationBlock)completionBlock;

+ (NSArray<NSString *> *)defaultScopes;

@end


NS_ASSUME_NONNULL_END
