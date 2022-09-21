//
//  PanBaiduNetdiskAuthState.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "PanBaiduNetdiskAuthState.h"
#import "PanBaiduNetdiskAuthRequest.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "NSError+PanBaiduNetdisk.h"
#import "PanBaiduNetdiskObject.h"

@interface PanBaiduNetdiskAuthState()

@property (nonatomic, nullable, strong) PanBaiduNetdiskAccessToken *token;
@property (nonatomic, strong) NSRecursiveLock *stateLock;
@property (nonatomic, strong) PanBaiduNetdiskNetworkClient *networkClient;
@property (nonatomic, weak) NSURLSessionDataTask *tokenUpdateTask;
@property (nonatomic, strong) NSMutableArray<PanBaiduNetdiskAccessTokenUpdateBlock> *tokenUpdateCompletionBlocks;

@end


@implementation PanBaiduNetdiskAuthState


- (instancetype)initWithToken:(PanBaiduNetdiskAccessToken * _Nullable)token
{
    self = [super init];
    if (self) {
        _token = token;
        self.stateLock = [NSRecursiveLock new];
        self.tokenUpdateCompletionBlocks = [NSMutableArray<PanBaiduNetdiskAccessTokenUpdateBlock> new];
        self.networkClient = [[PanBaiduNetdiskNetworkClient alloc] initWithURLSessionConfiguration:nil];
    }
    return self;
}

- (void)addTokenUpdateCompletionBlock:(PanBaiduNetdiskAccessTokenUpdateBlock)block{
    if (block == nil){
        NSParameterAssert(NO);
        return;
    }
    PanBaiduNetdiskAccessTokenUpdateBlock copiedBlock = [block copy];
    [self.stateLock lock];
    [self.tokenUpdateCompletionBlocks addObject:copiedBlock];
    [self.stateLock unlock];
}

- (PanBaiduNetdiskAccessToken *)token {
    PanBaiduNetdiskAccessToken *token = nil;
    [self.stateLock lock];
    token = _token;
    [self.stateLock unlock];
    return token;
}

- (void)processTokenUpdateCompletionBlocks{
    NSString *accessToken = nil;
    NSError *tokenUpdateError = nil;
    
    [self.stateLock lock];
    accessToken = [_token.accessToken copy];
    tokenUpdateError = [_token.tokenUpdateError copy];
    for (PanBaiduNetdiskAccessTokenUpdateBlock block in self.tokenUpdateCompletionBlocks){
        block(accessToken,tokenUpdateError);
    }
    [self.tokenUpdateCompletionBlocks removeAllObjects];
    [self.stateLock unlock];
}

#pragma mark - Token Update

- (void)completeTokenUpdateWithResponse:(NSDictionary *_Nullable)dictionary
                                  error:(NSError *_Nullable)error
{
    NSString *accessTokenUpdated = nil;
    NSNumber *expiresInUpdated = nil;
    NSString *refreshTokenUpdated = nil;
    NSString *scopeUpdated = nil;
    
    if (dictionary.count > 0) {
        accessTokenUpdated = [PanBaiduNetdiskObject stringForKey:@"access_token" inDictionary:dictionary];
        expiresInUpdated = [PanBaiduNetdiskObject numberForKey:@"expires_in" inDictionary:dictionary];
        refreshTokenUpdated = [PanBaiduNetdiskObject stringForKey:@"refresh_token" inDictionary:dictionary];
        scopeUpdated = [PanBaiduNetdiskObject stringForKey:@"scope" inDictionary:dictionary];
    }
    NSDate *tokenExpireDateUpdated = nil;
    if (expiresInUpdated && expiresInUpdated.longLongValue > 0) {
        tokenExpireDateUpdated = [NSDate dateWithTimeIntervalSinceNow:expiresInUpdated.longLongValue];
    }
    
    NSError *tokenUpdateError = error;
    
    [self.stateLock lock];
    
    PanBaiduNetdiskAccessToken *tokenUpdated = nil;
    
    if (tokenUpdateError) {
        tokenUpdated =
        [PanBaiduNetdiskAccessToken
         accessTokenWithClientID:_token.clientID
         clientSecret:_token.clientSecret
         redirectURI:_token.redirectURI
         scope:_token.scope
         accessToken:_token.accessToken
         refreshToken:_token.refreshToken
         expiresIn:_token.expiresIn
         tokenExpireDate:_token.tokenExpireDate
         tokenUpdateError:tokenUpdateError];
    }
    else {
        tokenUpdated =
        [PanBaiduNetdiskAccessToken
         accessTokenWithClientID:_token.clientID
         clientSecret:_token.clientSecret
         redirectURI:_token.redirectURI
         scope:scopeUpdated
         accessToken:accessTokenUpdated
         refreshToken:refreshTokenUpdated
         expiresIn:expiresInUpdated
         tokenExpireDate:tokenExpireDateUpdated
         tokenUpdateError:nil];
    }
   
    _token = tokenUpdated;
    [self.stateLock unlock];
    
    [self processTokenUpdateCompletionBlocks];
    
    if ([self.stateChangeDelegate respondsToSelector:@selector(panBaiduNetdiskAuthStateDidChange:)]){
        [self.stateChangeDelegate panBaiduNetdiskAuthStateDidChange:self];
    }
}

- (NSURLSessionDataTask * _Nullable)updateTokenWithCompletion:(PanBaiduNetdiskAccessTokenUpdateBlock)completion{
    [self addTokenUpdateCompletionBlock:completion];
    
    NSURLSessionDataTask *existingTokenUpdateTask = nil;
    [self.stateLock lock];
    existingTokenUpdateTask = self.tokenUpdateTask;
    [self.stateLock unlock];
    
    if (existingTokenUpdateTask) {
        return existingTokenUpdateTask;
    }
    
    NSString *clientID = nil;
    NSString *clientSecret = nil;
    NSString *refreshToken = nil;
    
    [self.stateLock lock];
    clientID = [_token.clientID copy];
    clientSecret = [_token.clientSecret copy];
    refreshToken = [_token.refreshToken copy];
    [self.stateLock unlock];
    
    NSParameterAssert(clientID);
    NSParameterAssert(clientSecret);
    NSParameterAssert(refreshToken);
    
    PanBaiduNetdiskTokenRefreshRequest *tokenRefreshRequest =
    [PanBaiduNetdiskTokenRefreshRequest requestWithClientID:clientID
                                               clientSecret:clientSecret
                                                  grantType:@"refresh_token"
                                               refreshToken:refreshToken];
    
    NSURLRequest *tokenRefreshURLRequest = [tokenRefreshRequest URLRequest];
    if (tokenRefreshURLRequest == nil) {
        NSParameterAssert(NO);
        NSError *cannotUpdateAccessTokenError =
        [NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotUpdateAccessToken];
        [self completeTokenUpdateWithResponse:nil error:cannotUpdateAccessTokenError];
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    NSURLSessionDataTask *tokenUpdateTask =
    [self.networkClient dataTaskWithRequest:tokenRefreshURLRequest
                          completionHandler:
     ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [PanBaiduNetdiskNetworkClient processResponse:response
                                             withData:data
                                                error:error
                                           completion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelf;
            [strongSelf completeTokenUpdateWithResponse:dictionary error:error];
        }];
    }];
    
    [self.stateLock lock];
    self.tokenUpdateTask = tokenUpdateTask;
    [self.stateLock unlock];
    
    [tokenUpdateTask resume];
    return tokenUpdateTask;
}

@end
