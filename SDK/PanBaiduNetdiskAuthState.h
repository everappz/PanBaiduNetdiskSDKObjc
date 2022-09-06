//
//  PanBaiduNetdiskAuthState.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduNetdiskAuthState;

@protocol PanBaiduNetdiskAuthStateChangeDelegate <NSObject>

- (void)panBaiduNetdiskAuthStateDidChange:(PanBaiduNetdiskAuthState *)state;

@end


@interface PanBaiduNetdiskAuthState : NSObject <NSSecureCoding>

- (instancetype)initWithClientID:(NSString * _Nullable)clientID
                    clientSecret:(NSString * _Nullable)clientSecret
                     redirectURI:(NSString * _Nullable)redirectURI
                           scope:(NSString * _Nullable)scope
                     accessToken:(NSString * _Nullable)accessToken
                    refreshToken:(NSString * _Nullable)refreshToken
                       expiresIn:(NSNumber * _Nullable)expiresIn
                 tokenExpireDate:(NSDate * _Nullable)tokenExpireDate;

@property (readonly, copy, nullable) NSString *clientID;

@property (readonly, copy, nullable) NSString *clientSecret;

@property (readonly, copy, nullable) NSString *redirectURI;

@property (readonly, copy, nullable) NSString *scope;

@property (readonly, copy, nullable) NSString *accessToken;

@property (readonly, copy, nullable) NSString *refreshToken;

@property (readonly, strong, nullable) NSNumber *expiresIn;

@property (readonly, strong, nullable) NSDate *tokenExpireDate;

@property (readonly, strong, nullable) NSError *tokenUpdateError;

@property (nonatomic, weak, nullable) id<PanBaiduNetdiskAuthStateChangeDelegate> stateChangeDelegate;

- (NSURLSessionDataTask *_Nullable)updateTokenWithCompletion:(PanBaiduNetdiskAccessTokenUpdateBlock)completion;

@end

NS_ASSUME_NONNULL_END
