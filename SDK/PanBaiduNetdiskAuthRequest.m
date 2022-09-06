//
//  PanBaiduNetdiskAuthRequest.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "PanBaiduNetdiskAuthRequest.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "PanBaiduNetdiskScopeUtilities.h"
#import "PanBaiduNetdiskConstants.h"

@implementation PanBaiduNetdiskAuthRequest

- (NSURLRequest * _Nullable)URLRequest {
    NSParameterAssert(NO);
    return nil;
}

@end

@interface PanBaiduNetdiskAuthorizationCodeRequest()

@property (nonatomic,copy)NSString *clientID;
@property (nonatomic,copy)NSString *scope;
@property (nonatomic,copy)NSString *redirectURI;
@property (nonatomic,copy)NSString *deviceID;
@property (nonatomic,copy)NSString *responseType;
@property (nonatomic,copy)NSString *display;

@end

@implementation PanBaiduNetdiskAuthorizationCodeRequest

+ (instancetype)requestWithClientID:(NSString *)clientID
                        redirectURI:(NSString *)redirectURI
                              scope:(NSString *)scope
                           deviceID:(NSString *)deviceID
                       responseType:(NSString *)responseType
                            display:(NSString *)display
{
    PanBaiduNetdiskAuthorizationCodeRequest *request = [PanBaiduNetdiskAuthorizationCodeRequest new];
    request.clientID = clientID;
    request.scope = scope;
    request.redirectURI = redirectURI;
    request.responseType = @"code";
    request.deviceID = deviceID;
    request.display = display;
    return request;
}

- (NSURLRequest * _Nullable)URLRequest {
    NSURL *tokenRequestURL = [kPanBaiduNetdiskOAuthURL URLByAppendingPathComponent:@"authorize"];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    NSParameterAssert(self.responseType);
    if (self.responseType) {
        [parameters setObject:self.responseType forKey:@"response_type"];
    }
    
    NSParameterAssert(self.clientID);
    if (self.clientID) {
        [parameters setObject:self.clientID forKey:@"client_id"];
    }
    
    NSParameterAssert(self.redirectURI);
    if (self.redirectURI) {
        [parameters setObject:self.redirectURI forKey:@"redirect_uri"];
    }
    
    NSParameterAssert(self.scope);
    if (self.scope) {
        [parameters setObject:self.scope forKey:@"scope"];
    }
    
    NSParameterAssert(self.deviceID);
    if (self.deviceID) {
        [parameters setObject:self.deviceID forKey:@"device_id"];
    }
    
    NSParameterAssert(self.display);
    if (self.display) {
        [parameters setObject:self.display forKey:@"display"];
    }
    
    NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:parameters inURL:tokenRequestURL];
    NSMutableURLRequest *URLRequest = [[NSURLRequest requestWithURL:requestURL] mutableCopy];
    URLRequest.HTTPMethod = @"GET";
    [PanBaiduNetdiskNetworkClient printRequest:URLRequest];
    return URLRequest;
}

@end


@interface PanBaiduNetdiskTokenExchangeRequest()

@property (nonatomic,copy)NSString *clientID;
@property (nonatomic,copy)NSString *clientSecret;
@property (nonatomic,copy)NSString *redirectURI;
@property (nonatomic,copy)NSString *grantType;
@property (nonatomic,copy)NSString *code;

@end


@implementation PanBaiduNetdiskTokenExchangeRequest

+ (instancetype)requestWithClientID:(NSString *)clientID
                       clientSecret:(NSString *)clientSecret
                        redirectURI:(NSString *)redirectURI
                          grantType:(NSString *)grantType
                               code:(NSString *)code
{
    PanBaiduNetdiskTokenExchangeRequest *request = [PanBaiduNetdiskTokenExchangeRequest new];
    
    request.clientID = clientID;
    request.clientSecret = clientSecret;
    request.redirectURI = redirectURI;
    request.grantType = grantType;
    request.code = code;
    
    return request;
}

- (NSURLRequest * _Nullable)URLRequest {
    NSURL *tokenRequestURL = [kPanBaiduNetdiskOAuthURL URLByAppendingPathComponent:@"token"];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    NSParameterAssert(self.grantType);
    if (self.grantType) {
        [parameters setObject:self.grantType forKey:@"grant_type"];
    }
    
    NSParameterAssert(self.clientID);
    if (self.clientID) {
        [parameters setObject:self.clientID forKey:@"client_id"];
    }
    
    NSParameterAssert(self.clientSecret);
    if (self.clientSecret) {
        [parameters setObject:self.clientSecret forKey:@"client_secret"];
    }
    
    NSParameterAssert(self.redirectURI);
    if (self.redirectURI) {
        [parameters setObject:self.redirectURI forKey:@"redirect_uri"];
    }
    
    NSParameterAssert(self.code);
    if (self.code) {
        [parameters setObject:self.code forKey:@"code"];
    }
    
    NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:parameters inURL:tokenRequestURL];
    NSMutableURLRequest *URLRequest = [[NSURLRequest requestWithURL:requestURL] mutableCopy];
    URLRequest.HTTPMethod = @"GET";
    [PanBaiduNetdiskNetworkClient printRequest:URLRequest];
    return URLRequest;
}

@end


@interface PanBaiduNetdiskTokenRefreshRequest()

@property (nonatomic,copy)NSString *clientID;
@property (nonatomic,copy)NSString *clientSecret;
@property (nonatomic,copy)NSString *grantType;
@property (nonatomic,copy)NSString *refreshToken;

@end


@implementation PanBaiduNetdiskTokenRefreshRequest

+ (instancetype)requestWithClientID:(NSString *)clientID
                       clientSecret:(NSString *)clientSecret
                          grantType:(NSString *)grantType
                       refreshToken:(NSString *)refreshToken
{
    PanBaiduNetdiskTokenRefreshRequest *request = [PanBaiduNetdiskTokenRefreshRequest new];
    request.clientID = clientID;
    request.clientSecret = clientSecret;
    request.refreshToken = refreshToken;
    request.grantType = grantType;
    return request;
}

- (NSURLRequest * _Nullable)URLRequest {
    NSURL *tokenRequestURL = [kPanBaiduNetdiskOAuthURL URLByAppendingPathComponent:@"token"];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    NSParameterAssert(self.grantType);
    if (self.grantType) {
        [parameters setObject:self.grantType forKey:@"grant_type"];
    }
    
    NSParameterAssert(self.clientID);
    if (self.clientID) {
        [parameters setObject:self.clientID forKey:@"client_id"];
    }
    
    NSParameterAssert(self.clientSecret);
    if (self.clientSecret) {
        [parameters setObject:self.clientSecret forKey:@"client_secret"];
    }
    
    NSParameterAssert(self.refreshToken);
    if (self.refreshToken) {
        [parameters setObject:self.refreshToken forKey:@"refresh_token"];
    }
    
    NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:parameters inURL:tokenRequestURL];
    NSMutableURLRequest *URLRequest = [[NSURLRequest requestWithURL:requestURL] mutableCopy];
    URLRequest.HTTPMethod = @"GET";
    [PanBaiduNetdiskNetworkClient printRequest:URLRequest];
    return URLRequest;
}

@end



