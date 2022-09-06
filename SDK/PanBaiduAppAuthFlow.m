//
//  PanBaiduAppAuthFlow.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import "PanBaiduAppAuthFlow.h"
#import "PanBaiduNetdiskAPIClient.h"
#import "PanBaiduNetdiskConstants.h"
#import "NSError+PanBaiduNetdisk.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "PanBaiduNetdiskAuthRequest.h"
#import "PanBaiduNetdiskAuthorizationWebViewCoordinator.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "PanBaiduNetdiskAuthState.h"
#import "PanBaiduNetdiskObject.h"

@interface PanBaiduAppAuthFlow()

@property(atomic, assign) BOOL started;
@property(atomic, assign) BOOL cancelled;
@property(atomic, assign) BOOL completed;

@property(nonatomic, strong) PanBaiduNetdiskAPIClient *apiClient;
@property(nonatomic, strong) PanBaiduNetdiskAuthorizationWebViewCoordinator *webViewCoordinator;
@property(nonatomic, strong) PanBaiduNetdiskNetworkClient *networkClient;
@property(nonatomic, weak) NSURLSessionDataTask *tokenExchangeDataTask;

@end



@implementation PanBaiduAppAuthFlow


- (instancetype)init {
    self = [super init];
    if (self) {
        self.apiClient = [[PanBaiduNetdiskAPIClient alloc] initWithURLSessionConfiguration:nil authProvider:nil];
        self.networkClient = [[PanBaiduNetdiskNetworkClient alloc] initWithURLSessionConfiguration:nil];
    }
    return self;
}

- (void)start {
    if (self.started){
        NSParameterAssert(NO);
        return;
    }
    
    self.started = YES;
    
    NSParameterAssert(self.clientID);
    NSParameterAssert(self.redirectURI);
    NSParameterAssert(self.scopes);
    NSParameterAssert(self.appID);
    
    PanBaiduNetdiskAuthorizationCodeRequest *authStartRequest =
    [PanBaiduNetdiskAuthorizationCodeRequest requestWithClientID:self.clientID
                                                     redirectURI:self.redirectURI
                                                           scope:[self.scopes componentsJoinedByString:@","]
                                                        deviceID:self.appID
                                                    responseType:@"code"
                                                         display:@"mobile"];
    
    NSURLRequest *authStartURLRequest = authStartRequest.URLRequest;
    
    if (authStartURLRequest == nil) {
        [self completeFlowWithAuthState:nil error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetAuthURL]];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        PanBaiduNetdiskAuthorizationWebViewCoordinator *coordinator =
        [[PanBaiduNetdiskAuthorizationWebViewCoordinator alloc] initWithWebView:self.webView
                                                                    redirectURI:[NSURL URLWithString:self.redirectURI]];
        coordinator.webViewDidStartLoadingBlock = self.webViewDidStartLoadingBlock;
        coordinator.webViewDidFinishLoadingBlock = self.webViewDidFinishLoadingBlock;
        coordinator.webViewDidFailWithErrorBlock = self.webViewDidFailWithErrorBlock;
        
        PanBaiduNetdiskMakeWeakSelf;
        coordinator.completionBlock = ^(WKWebView *webView, NSURL * _Nullable webViewRedirectURL, NSError * _Nullable error)
        {
            PanBaiduNetdiskMakeStrongSelf;
            NSString *code = [PanBaiduAppAuthFlow codeFromURL:webViewRedirectURL];
            if (code) {
                [strongSelf getTokenUsingCode:code];
            }
            else{
                [strongSelf completeFlowWithAuthState:nil error:error];
            }
        };
        self.webViewCoordinator = coordinator;
        const BOOL presentUserAgentResult = [coordinator presentExternalUserAgentRequest:authStartURLRequest];
        
        if (presentUserAgentResult == NO) {
            [self completeFlowWithAuthState:nil error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetAuthURL]];
        }
    });
}

+ (NSString *_Nullable)codeFromURL:(NSURL *)URL{
    return [[PanBaiduNetdiskNetworkClient queryDictionaryFromURL:URL] objectForKey:@"code"];
}

- (void)getTokenUsingCode:(NSString *)code{
    NSParameterAssert(self.clientID);
    NSParameterAssert(self.redirectURI);
    NSParameterAssert(self.clientSecret);
    NSParameterAssert(code);
    
    PanBaiduNetdiskTokenExchangeRequest *tokenExchangeRequest =
    [PanBaiduNetdiskTokenExchangeRequest requestWithClientID:self.clientID
                                                clientSecret:self.clientSecret
                                                 redirectURI:self.redirectURI
                                                   grantType:@"authorization_code"
                                                        code:code];
    
    NSURLRequest *tokenExchangeURLRequest = [tokenExchangeRequest URLRequest];
    if (tokenExchangeURLRequest == nil) {
        [self completeFlowWithAuthState:nil error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetAccessToken]];
        return;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    NSURLSessionDataTask *tokenExchangeDataTask =
    [self.networkClient dataTaskWithRequest:tokenExchangeURLRequest
                          completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelf;
        [PanBaiduNetdiskNetworkClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            if ([dictionary objectForKey:@"access_token"] == nil) {
                [strongSelf completeFlowWithAuthState:nil error:error];
            }
            else{
                [strongSelf tokenRequestDidCompleteWithDictionary:dictionary];
            }
        } withData:data response:response error:error];
    }];
    self.tokenExchangeDataTask = tokenExchangeDataTask;
    [tokenExchangeDataTask resume];
}

/*
 The return value is described as follows:
 
 Parameters    Type    Notes
 access_token    string    Access Token, which is the certificate that calls the network disk open API to access user-authorized resources.
 expires_in    int    Access Token is valid in seconds.
 refresh_token    string    Used to refresh Access Token, valid for 10 years.
 scope    string    Access Token's final access, that is, the list of the user's actual authorizations.
 */

- (void)tokenRequestDidCompleteWithDictionary:(NSDictionary *)dictionary{
    NSString *access_token = [PanBaiduNetdiskObject stringForKey:@"access_token" inDictionary:dictionary];
    NSNumber *expires_in = [PanBaiduNetdiskObject numberForKey:@"expires_in" inDictionary:dictionary];
    NSString *refresh_token = [PanBaiduNetdiskObject stringForKey:@"refresh_token" inDictionary:dictionary];
    NSString *scope = [PanBaiduNetdiskObject stringForKey:@"scope" inDictionary:dictionary];
    
    NSParameterAssert(access_token);
    NSParameterAssert(refresh_token);
    
    NSDate *tokenExpireDate = nil;
    if (expires_in && expires_in.longLongValue > 0){
        tokenExpireDate = [NSDate dateWithTimeIntervalSinceNow:expires_in.longLongValue];
    }
    
    NSParameterAssert(self.clientID);
    NSParameterAssert(self.clientSecret);
    NSParameterAssert(self.redirectURI);
    
    PanBaiduNetdiskAuthState *authState = [[PanBaiduNetdiskAuthState alloc] initWithClientID:self.clientID
                                                                                clientSecret:self.clientSecret
                                                                                 redirectURI:self.redirectURI
                                                                                       scope:scope
                                                                                 accessToken:access_token
                                                                                refreshToken:refresh_token
                                                                                   expiresIn:expires_in
                                                                             tokenExpireDate:tokenExpireDate];
    
    [self completeFlowWithAuthState:authState error:nil];
}

- (void)completeFlowWithAuthState:(PanBaiduNetdiskAuthState *_Nullable)authState
                            error:(NSError *_Nullable)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completed){
            NSParameterAssert(NO);
            return;
        }
        if (self.cancelled){
            return;
        }
        if (self.completionBlock){
            self.completionBlock(authState, error);
        }
        [self cleanUp];
        self.completed = YES;
    });
}

- (void)cancel {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.cancelled){
            NSParameterAssert(NO);
            return;
        }
        [self.tokenExchangeDataTask cancel];
        [self cleanUp];
        self.cancelled = YES;
    });
}

- (void)cleanUp{
    NSParameterAssert([NSThread isMainThread]);
    [self.webViewCoordinator dismissExternalUserAgentAnimated:NO
                                                   completion:nil];
    self.webViewCoordinator = nil;
}

@end
