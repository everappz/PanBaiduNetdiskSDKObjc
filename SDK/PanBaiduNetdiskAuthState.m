//
//  PanBaiduNetdiskAuthState.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "PanBaiduNetdiskAuthState.h"
#import "PanBaiduNetdiskAuthRequest.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "NSError+PanBaiduNetdisk.h"
#import "PanBaiduNetdiskObject.h"

@interface PanBaiduNetdiskAuthState()

@property (nonatomic, copy, nullable) NSString *clientID;
@property (nonatomic, copy, nullable) NSString *clientSecret;
@property (nonatomic, copy, nullable) NSString *redirectURI;
@property (nonatomic, copy, nullable) NSString *scope;
@property (nonatomic, copy, nullable) NSString *accessToken;
@property (nonatomic, copy, nullable) NSString *refreshToken;
@property (nonatomic, strong, nullable) NSNumber *expiresIn;
@property (nonatomic, strong, nullable) NSDate *tokenExpireDate;
@property (nonatomic, strong, nullable) NSError *tokenUpdateError;

@property (nonatomic, strong) PanBaiduNetdiskNetworkClient *networkClient;

@property (nonatomic, weak) NSURLSessionDataTask *tokenUpdateTask;
@property (nonatomic, strong) NSRecursiveLock *tokenUpdateTaskLock;
@property (nonatomic, strong) NSMutableArray<PanBaiduNetdiskAccessTokenUpdateBlock> *tokenUpdateCompletionBlocks;
@property (nonatomic, strong) NSRecursiveLock *tokenUpdateCompletionBlocksLock;

@end


@implementation PanBaiduNetdiskAuthState

- (instancetype)initWithClientID:(NSString * _Nullable)clientID
                    clientSecret:(NSString * _Nullable)clientSecret
                     redirectURI:(NSString * _Nullable)redirectURI
                           scope:(NSString * _Nullable)scope
                     accessToken:(NSString * _Nullable)accessToken
                    refreshToken:(NSString * _Nullable)refreshToken
                       expiresIn:(NSNumber * _Nullable)expiresIn
                 tokenExpireDate:(NSDate * _Nullable)tokenExpireDate
{
    self = [super init];
    if (self) {
        self.clientID = clientID;
        self.clientSecret = clientSecret;
        self.redirectURI = redirectURI;
        self.scope = scope;
        self.accessToken = accessToken;
        self.refreshToken = refreshToken;
        self.expiresIn = expiresIn;
        self.tokenExpireDate = tokenExpireDate;
        self.tokenUpdateCompletionBlocksLock = [NSRecursiveLock new];
        self.tokenUpdateTaskLock = [NSRecursiveLock new];
    }
    return self;
}

- (PanBaiduNetdiskNetworkClient *)networkClient {
    if (_networkClient == nil) {
        _networkClient = [[PanBaiduNetdiskNetworkClient alloc] initWithURLSessionConfiguration:nil];
    }
    return _networkClient;
}

- (NSMutableArray<PanBaiduNetdiskAccessTokenUpdateBlock> *)tokenUpdateCompletionBlocks{
    if (_tokenUpdateCompletionBlocks == nil) {
        _tokenUpdateCompletionBlocks = [NSMutableArray<PanBaiduNetdiskAccessTokenUpdateBlock> new];
    }
    return _tokenUpdateCompletionBlocks;
}

- (void)addTokenUpdateCompletionBlock:(PanBaiduNetdiskAccessTokenUpdateBlock)block{
    if (block == nil){
        NSParameterAssert(NO);
        return;
    }
    PanBaiduNetdiskAccessTokenUpdateBlock copiedBlock = [block copy];
    [self.tokenUpdateCompletionBlocksLock lock];
    [self.tokenUpdateCompletionBlocks addObject:copiedBlock];
    [self.tokenUpdateCompletionBlocksLock unlock];
}

- (void)processTokenUpdateCompletionBlocks{
    [self.tokenUpdateCompletionBlocksLock lock];
    NSString *accessToken = self.accessToken;
    NSError *tokenUpdateError = self.tokenUpdateError;
    for (PanBaiduNetdiskAccessTokenUpdateBlock block in self.tokenUpdateCompletionBlocks){
        block(accessToken,tokenUpdateError);
    }
    [self.tokenUpdateCompletionBlocks removeAllObjects];
    [self.tokenUpdateCompletionBlocksLock unlock];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        _expiresIn = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"expiresIn"];
        _refreshToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"refreshToken"];
        _accessToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accessToken"];
        _scope = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"scope"];
        _redirectURI = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"redirectURI"];
        _clientSecret = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"clientSecret"];
        _clientID = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"clientID"];
        _tokenExpireDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"tokenExpireDate"];
        _tokenUpdateError = [aDecoder decodeObjectOfClass:[NSError class] forKey:@"tokenUpdateError"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_expiresIn forKey:@"expiresIn"];
    [aCoder encodeObject:_refreshToken forKey:@"refreshToken"];
    [aCoder encodeObject:_accessToken forKey:@"accessToken"];
    [aCoder encodeObject:_scope forKey:@"scope"];
    [aCoder encodeObject:_redirectURI forKey:@"redirectURI"];
    [aCoder encodeObject:_clientSecret forKey:@"clientSecret"];
    [aCoder encodeObject:_clientID forKey:@"clientID"];
    [aCoder encodeObject:_tokenExpireDate forKey:@"tokenExpireDate"];
    [aCoder encodeObject:_tokenUpdateError forKey:@"tokenUpdateError"];
}

#pragma mark - Token Update

- (void)completeTokenUpdateWithResponse:(NSDictionary *_Nullable)dictionary
                                  error:(NSError *_Nullable)error
{
    NSString *access_token = [PanBaiduNetdiskObject stringForKey:@"access_token" inDictionary:dictionary];
    NSNumber *expires_in = [PanBaiduNetdiskObject numberForKey:@"expires_in" inDictionary:dictionary];
    NSString *refresh_token = [PanBaiduNetdiskObject stringForKey:@"refresh_token" inDictionary:dictionary];
    NSString *scope = [PanBaiduNetdiskObject stringForKey:@"scope" inDictionary:dictionary];
    
    NSParameterAssert(access_token);
    
    NSDate *tokenExpireDate = nil;
    if (expires_in && expires_in.longLongValue > 0){
        tokenExpireDate = [NSDate dateWithTimeIntervalSinceNow:expires_in.longLongValue];
    }
    
    if (access_token && access_token.length > 0) {
        self.accessToken = access_token;
    }
    if (expires_in) {
        self.expiresIn = expires_in;
    }
    
    if (refresh_token && refresh_token.length > 0) {
        self.refreshToken = refresh_token;
    }
    if (scope && scope.length > 0) {
        self.scope = scope;
    }
    if (tokenExpireDate) {
        self.tokenExpireDate = tokenExpireDate;
    }
    
    self.tokenUpdateError = error;
    
    [self processTokenUpdateCompletionBlocks];
    
    if ([self.stateChangeDelegate respondsToSelector:@selector(panBaiduNetdiskAuthStateDidChange:)]){
        [self.stateChangeDelegate panBaiduNetdiskAuthStateDidChange:self];
    }
}

- (NSURLSessionDataTask * _Nullable)updateTokenWithCompletion:(PanBaiduNetdiskAccessTokenUpdateBlock)completion{
    [self addTokenUpdateCompletionBlock:completion];
    
    NSURLSessionDataTask *existingTokenUpdateTask = nil;
    [self.tokenUpdateTaskLock lock];
    existingTokenUpdateTask = self.tokenUpdateTask;
    [self.tokenUpdateTaskLock unlock];
    
    if (existingTokenUpdateTask) {
        return existingTokenUpdateTask;
    }
    
    NSParameterAssert(self.clientID);
    NSParameterAssert(self.clientSecret);
    NSParameterAssert(self.refreshToken);
    
    PanBaiduNetdiskTokenRefreshRequest *tokenRefreshRequest =
    [PanBaiduNetdiskTokenRefreshRequest requestWithClientID:self.clientID
                                               clientSecret:self.clientSecret
                                                  grantType:@"refresh_token"
                                               refreshToken:self.refreshToken];
    
    NSURLRequest *tokenRefreshURLRequest = [tokenRefreshRequest URLRequest];
    if (tokenRefreshURLRequest == nil){
        NSParameterAssert(NO);
        [self completeTokenUpdateWithResponse:nil error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotUpdateAccessToken]];
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    NSURLSessionDataTask *tokenUpdateTask = [self.networkClient dataTaskWithRequest:tokenRefreshURLRequest
                                                                  completionHandler:
                                             ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [PanBaiduNetdiskNetworkClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelf;
            [strongSelf completeTokenUpdateWithResponse:dictionary error:error];
        } withData:data response:response error:error];
    }];
    
    [self.tokenUpdateTaskLock lock];
    self.tokenUpdateTask = tokenUpdateTask;
    [self.tokenUpdateTaskLock unlock];
    
    [tokenUpdateTask resume];
    return tokenUpdateTask;
}

@end
