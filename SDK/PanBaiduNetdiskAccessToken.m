//
//  PanBaiduNetdiskAccessToken.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/12/21.
//

#import "PanBaiduNetdiskAccessToken.h"

@interface PanBaiduNetdiskAccessToken ()

@property (nonatomic, copy, nullable) NSString *clientID;
@property (nonatomic, copy, nullable) NSString *clientSecret;
@property (nonatomic, copy, nullable) NSString *redirectURI;
@property (nonatomic, copy, nullable) NSString *scope;
@property (nonatomic, copy, nullable) NSString *accessToken;
@property (nonatomic, copy, nullable) NSString *refreshToken;
@property (nonatomic, copy, nullable) NSNumber *expiresIn;
@property (nonatomic, copy, nullable) NSDate *tokenExpireDate;
@property (nonatomic, strong, nullable) NSError *tokenUpdateError;

@end


@implementation PanBaiduNetdiskAccessToken

+ (instancetype)accessTokenWithClientID:(NSString * _Nullable)clientID
                           clientSecret:(NSString * _Nullable)clientSecret
                            redirectURI:(NSString * _Nullable)redirectURI
                                  scope:(NSString * _Nullable)scope
                            accessToken:(NSString * _Nullable)accessToken
                           refreshToken:(NSString * _Nullable)refreshToken
                              expiresIn:(NSNumber * _Nullable)expiresIn
                        tokenExpireDate:(NSDate * _Nullable)tokenExpireDate
                       tokenUpdateError:(NSError * _Nullable)tokenUpdateError
{
    PanBaiduNetdiskAccessToken *model = [PanBaiduNetdiskAccessToken new];
    model.clientID = clientID;
    model.clientSecret = clientSecret;
    model.redirectURI = redirectURI;
    model.scope = scope;
    model.accessToken = accessToken;
    model.refreshToken = refreshToken;
    model.expiresIn = expiresIn;
    model.tokenExpireDate = tokenExpireDate;
    model.tokenUpdateError = tokenUpdateError;
    return model;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        _clientID = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"clientID"];
        _clientSecret = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"clientSecret"];
        _redirectURI = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"redirectURI"];
        _scope = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"scope"];
        _accessToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accessToken"];
        _refreshToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"refreshToken"];
        _expiresIn = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"expiresIn"];
        _tokenExpireDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"tokenExpireDate"];
        _tokenUpdateError = [aDecoder decodeObjectOfClass:[NSError class] forKey:@"tokenUpdateError"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_clientID forKey:@"clientID"];
    [aCoder encodeObject:_clientSecret forKey:@"clientSecret"];
    [aCoder encodeObject:_redirectURI forKey:@"redirectURI"];
    [aCoder encodeObject:_scope forKey:@"scope"];
    [aCoder encodeObject:_accessToken forKey:@"accessToken"];
    [aCoder encodeObject:_refreshToken forKey:@"refreshToken"];
    [aCoder encodeObject:_expiresIn forKey:@"expiresIn"];
    [aCoder encodeObject:_tokenExpireDate forKey:@"tokenExpireDate"];
    [aCoder encodeObject:_tokenUpdateError forKey:@"tokenUpdateError"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    PanBaiduNetdiskAccessToken *model = [[[self class] allocWithZone:zone] init];
    
    model->_clientID = [_clientID copy];
    model->_clientSecret = [_clientSecret copy];
    model->_redirectURI = [_redirectURI copy];
    model->_scope = [_scope copy];
    model->_accessToken = [_accessToken copy];
    model->_refreshToken = [_refreshToken copy];
    model->_expiresIn = [_expiresIn copy];
    model->_tokenExpireDate = [_tokenExpireDate copy];
    model->_tokenUpdateError = [_tokenUpdateError copy];
    
    return model;
}



@end
