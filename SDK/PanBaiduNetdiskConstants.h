//
//  PanBaiduNetdiskConstants.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define PanBaiduNetdiskMakeWeakReferenceWithName(reference, weakReferenceName) __weak __typeof(reference) weakReferenceName = reference;
#define PanBaiduNetdiskMakeStrongReferenceWithName(reference, strongReferenceName) __strong __typeof(reference) strongReferenceName = reference;

#define PanBaiduNetdiskMakeWeakReference(reference) PanBaiduNetdiskMakeWeakReferenceWithName(reference, weak_##reference)
#define PanBaiduNetdiskMakeStrongReference(reference) PanBaiduNetdiskMakeStrongReferenceWithName(reference, strong_##reference)

#define PanBaiduNetdiskMakeStrongReferenceWithNameAndReturnValueIfNil(reference, strongReferenceName, value) \
PanBaiduNetdiskMakeStrongReferenceWithName(reference, strongReferenceName); \
if (nil == strongReferenceName) { \
return (value); \
} \

#define PanBaiduNetdiskMakeStrongReferenceWithNameAndReturnIfNil(reference, strongReferenceName) PanBaiduNetdiskMakeStrongReferenceWithNameAndReturnValueIfNil(reference, strongReferenceName, (void)0)

#define PanBaiduNetdiskMakeWeakSelf PanBaiduNetdiskMakeWeakReferenceWithName(self, weakSelf);
#define PanBaiduNetdiskMakeStrongSelf PanBaiduNetdiskMakeWeakReferenceWithName(weakSelf, strongSelf);

#define PanBaiduNetdiskMakeStrongSelfAndReturnIfNil PanBaiduNetdiskMakeStrongReferenceWithNameAndReturnIfNil(weakSelf,strongSelf);

#define kPanBaiduNetdiskContentTypeApplicationJSON @"application/json"
#define kPanBaiduNetdiskContentTypeMultipartRelated @"multipart/related"
#define kPanBaiduNetdiskContentTypeApplicationXWWWFormURLEncoded @"application/x-www-form-urlencoded"

#define kPanBaiduNetdiskOAuthURL [NSURL URLWithString:@"https://openapi.baidu.com/oauth/2.0/"]
#define kPanBaiduNetdiskXpanURL [NSURL URLWithString:@"https://pan.baidu.com/rest/2.0/xpan"]
#define kPanBaiduNetdiskNasURL [kPanBaiduNetdiskXpanURL URLByAppendingPathComponent:@"nas"]
#define kPanBaiduNetdiskFileURL [kPanBaiduNetdiskXpanURL URLByAppendingPathComponent:@"file"]
#define kPanBaiduNetdiskMultimediaURL [kPanBaiduNetdiskXpanURL URLByAppendingPathComponent:@"multimedia"]

@class WKWebView;
@class PanBaiduNetdiskAuthState;
@class PanBaiduNetdiskAccessToken;

extern NSString * const PanBaiduNetdiskAccessTokenDataKey;
extern NSString * const PanBaiduNetdiskUserIDKey;
extern NSString * const PanBaiduNetdiskUserNameKey;

typedef void(^PanBaiduNetdiskAPIClientDictionaryCompletionBlock)(NSDictionary *_Nullable dictionary, NSError * _Nullable error);
typedef void(^PanBaiduNetdiskAPIClientArrayCompletionBlock)(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error);
typedef void(^PanBaiduNetdiskAPIClientVoidCompletionBlock)(void);
typedef void(^PanBaiduNetdiskAPIClientErrorCompletionBlock)(NSError * _Nullable error);
typedef void(^PanBaiduNetdiskAPIClientDidReceiveDataBlock)(NSData * _Nullable data);
typedef void(^PanBaiduNetdiskAPIClientDidReceiveResponseBlock)(NSURLResponse * _Nullable response);
typedef void(^PanBaiduNetdiskAPIClientProgressBlock)(float progress);
typedef void(^PanBaiduNetdiskAPIClientURLCompletionBlock)(NSURL *_Nullable location, NSError * _Nullable error);
typedef void(^PanBaiduNetdiskAPIClientAccessTokenCompletionBlock)(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error);

typedef void(^PanBaiduNetdiskAuthorizationWebViewCoordinatorLoadingBlock)(WKWebView *webView);
typedef void(^PanBaiduNetdiskAuthorizationWebViewCoordinatorErrorBlock)(WKWebView *webView, NSError *webViewError);
typedef void(^PanBaiduNetdiskAuthorizationWebViewCoordinatorCompletionBlock)(WKWebView *webView, NSURL * _Nullable webViewRedirectURL, NSError * _Nullable error);

typedef void (^PanBaiduNetdiskAccessTokenUpdateBlock)(NSString *_Nullable accessToken, NSError *_Nullable error);
typedef void (^PanBaiduNetdiskAccessTokenGetBlock)(PanBaiduNetdiskAccessToken *_Nullable accessToken, NSError *_Nullable error);

typedef void (^PanBaiduNetdiskAppAuthManagerAuthorizationBlock)(PanBaiduNetdiskAuthState *_Nullable authState, NSError *_Nullable error);

NS_ASSUME_NONNULL_END
