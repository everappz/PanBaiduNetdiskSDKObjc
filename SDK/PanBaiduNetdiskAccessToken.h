//
//  PanBaiduNetdiskAccessToken.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PanBaiduNetdiskAccessToken : NSObject <NSSecureCoding,NSCopying>

@property (nonatomic, readonly, copy, nullable) NSString *clientID;
@property (nonatomic, readonly, copy, nullable) NSString *clientSecret;
@property (nonatomic, readonly, copy, nullable) NSString *redirectURI;
@property (nonatomic, readonly, copy, nullable) NSString *scope;
@property (nonatomic, readonly, copy, nullable) NSString *accessToken;
@property (nonatomic, readonly, copy, nullable) NSString *refreshToken;
@property (nonatomic, readonly, copy, nullable) NSNumber *expiresIn;
@property (nonatomic, readonly, copy, nullable) NSDate *tokenExpireDate;
@property (nonatomic, readonly, strong, nullable) NSError *tokenUpdateError;

+ (instancetype)accessTokenWithClientID:(NSString * _Nullable)clientID
                           clientSecret:(NSString * _Nullable)clientSecret
                            redirectURI:(NSString * _Nullable)redirectURI
                                  scope:(NSString * _Nullable)scope
                            accessToken:(NSString * _Nullable)accessToken
                           refreshToken:(NSString * _Nullable)refreshToken
                              expiresIn:(NSNumber * _Nullable)expiresIn
                        tokenExpireDate:(NSDate * _Nullable)tokenExpireDate
                       tokenUpdateError:(NSError * _Nullable)tokenUpdateError;

@end

NS_ASSUME_NONNULL_END
