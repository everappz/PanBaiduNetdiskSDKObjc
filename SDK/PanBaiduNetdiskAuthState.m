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
@property (nonatomic, strong) NSRecursiveLock *tokenAccessLock;
@property (nonatomic, strong) PanBaiduNetdiskNetworkClient *networkClient;
@property (nonatomic, weak) NSURLSessionDataTask *tokenUpdateTask;
@property (nonatomic, strong) NSMutableArray<PanBaiduNetdiskAccessTokenUpdateBlock> *tokenCompletionBlocks;
@property (nonatomic, strong) NSRecursiveLock *tokenUpdateLock;

@end


@implementation PanBaiduNetdiskAuthState


- (instancetype)initWithToken:(PanBaiduNetdiskAccessToken * _Nullable)token
{
    self = [super init];
    if (self) {
        _token = token;
        self.tokenUpdateLock = [NSRecursiveLock new];
        self.tokenAccessLock = [NSRecursiveLock new];
        self.tokenCompletionBlocks = [NSMutableArray<PanBaiduNetdiskAccessTokenUpdateBlock> new];
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
    [self.tokenUpdateLock lock];
    [self.tokenCompletionBlocks addObject:copiedBlock];
    [self.tokenUpdateLock unlock];
}

- (PanBaiduNetdiskAccessToken *)token {
    PanBaiduNetdiskAccessToken *token = nil;
    [self.tokenUpdateLock lock];
    token = _token;
    [self.tokenUpdateLock unlock];
    return token;
}

- (void)processTokenUpdateCompletionBlocks{
    NSString *accessToken = nil;
    NSError *tokenUpdateError = nil;
    
    [self.tokenAccessLock lock];
    accessToken = [_token.accessToken copy];
    tokenUpdateError = [_token.tokenUpdateError copy];
    [self.tokenAccessLock unlock];
    
    [self.tokenUpdateLock lock];
    for (PanBaiduNetdiskAccessTokenUpdateBlock block in self.tokenCompletionBlocks){
        block(accessToken,tokenUpdateError);
    }
    [self.tokenCompletionBlocks removeAllObjects];
    [self.tokenUpdateLock unlock];
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
    
    [self.tokenAccessLock lock];
    
    PanBaiduNetdiskAccessToken *tokenUpdated =
    [PanBaiduNetdiskAccessToken
     accessTokenWithClientID:_token.clientID
     clientSecret:_token.clientSecret
     redirectURI:_token.redirectURI
     scope:scope
     accessToken:access_token
     refreshToken:refresh_token
     expiresIn:expires_in
     tokenExpireDate:tokenExpireDate
     tokenUpdateError:error];
    
    _token = tokenUpdated;
    [self.tokenAccessLock unlock];
    
    [self processTokenUpdateCompletionBlocks];
    
    if ([self.stateChangeDelegate respondsToSelector:@selector(panBaiduNetdiskAuthStateDidChange:)]){
        [self.stateChangeDelegate panBaiduNetdiskAuthStateDidChange:self];
    }
}

- (NSURLSessionDataTask * _Nullable)updateTokenWithCompletion:(PanBaiduNetdiskAccessTokenUpdateBlock)completion{
    [self addTokenUpdateCompletionBlock:completion];
    
    NSURLSessionDataTask *existingTokenUpdateTask = nil;
    [self.tokenUpdateLock lock];
    existingTokenUpdateTask = self.tokenUpdateTask;
    [self.tokenUpdateLock unlock];
    
    if (existingTokenUpdateTask) {
        return existingTokenUpdateTask;
    }
    
    NSString *clientID = nil;
    NSString *clientSecret = nil;
    NSString *refreshToken = nil;
    
    [self.tokenAccessLock lock];
    clientID = [_token.clientID copy];
    clientSecret = [_token.clientSecret copy];
    refreshToken = [_token.refreshToken copy];
    [self.tokenAccessLock unlock];
    
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
        [self completeTokenUpdateWithResponse:nil error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotUpdateAccessToken]];
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
    
    [self.tokenUpdateLock lock];
    self.tokenUpdateTask = tokenUpdateTask;
    [self.tokenUpdateLock unlock];
    
    [tokenUpdateTask resume];
    return tokenUpdateTask;
}

@end
