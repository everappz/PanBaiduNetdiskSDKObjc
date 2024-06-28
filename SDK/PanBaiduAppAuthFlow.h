//
//  PanBaiduAppAuthFlow.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "PanBaiduNetdiskConstants.h"


NS_ASSUME_NONNULL_BEGIN

@interface PanBaiduAppAuthFlow : NSObject

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSString *redirectURI;
@property (nonatomic, copy) NSArray<NSString *> *scopes;

@property (nonatomic, weak, nullable) UIViewController *viewController;

@property (nonatomic, strong, nullable) WKWebView *webView;
@property (nonatomic, copy) PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock webViewDidStartLoadingBlock;
@property (nonatomic, copy) PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock webViewDidFinishLoadingBlock;
@property (nonatomic, copy) PanBaiduNetdiskAuthorizationWebViewCoordinatorErrorBlock webViewDidFailWithErrorBlock;
@property (nonatomic, copy) PanBaiduNetdiskAppAuthManagerAuthorizationBlock completionBlock;

- (void)start;
- (void)cancel;

- (void)handleRedirectURL:(NSURL *)redirectURL;

@end

NS_ASSUME_NONNULL_END
