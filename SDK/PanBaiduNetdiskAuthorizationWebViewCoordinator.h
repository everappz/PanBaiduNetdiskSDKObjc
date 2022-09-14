//
//  PanBaiduNetdiskAuthorizationWebViewCoordinator.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "PanBaiduNetdiskConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface PanBaiduNetdiskAuthorizationWebViewCoordinator : NSObject

- (instancetype)initWithWebView:(WKWebView *)webView
                    redirectURI:(NSURL *)redirectURI;

@property (nonatomic, weak, readonly) WKWebView *webView;
@property (nonatomic, strong, readonly) NSURL *redirectURI;

@property (nonatomic,copy) PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock webViewDidStartLoadingBlock;
@property (nonatomic,copy) PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock webViewDidFinishLoadingBlock;
@property (nonatomic,copy) PanBaiduNetdiskAuthorizationWebViewCoordinatorErrorBlock webViewDidFailWithErrorBlock;
@property (nonatomic,copy) PanBaiduNetdiskAuthorizationWebViewCoordinatorCompletionBlock completionBlock;

- (BOOL)presentExternalUserAgentRequest:(NSURLRequest *)request;
- (void)dismissExternalUserAgentAnimated:(BOOL)animated
                              completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
