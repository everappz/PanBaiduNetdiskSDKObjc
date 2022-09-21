//
//  PanBaiduAppAuthProvider.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import "PanBaiduAppAuthProvider.h"
#import "PanBaiduNetdiskConstants.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "PanBaiduNetdiskAuthState.h"
#import "PanBaiduNetdiskAccessToken.h"
#import "NSError+PanBaiduNetdisk.h"

NSString * const PanBaiduAppAuthProviderDidChangeState = @"PanBaiduAppAuthProviderDidChangeState";

@interface PanBaiduAppAuthProvider()<PanBaiduNetdiskAuthStateChangeDelegate>

@property (nonatomic, strong) PanBaiduNetdiskAuthState *authState;

@property (nonatomic, copy) NSString *identifier;

@end




@implementation PanBaiduAppAuthProvider

- (instancetype)initWithIdentifier:(NSString *)identifier
                             state:(PanBaiduNetdiskAuthState *)authState
{
    NSParameterAssert(authState);
    if (authState == nil){
        return nil;
    }
    
    NSParameterAssert(identifier);
    if (identifier == nil){
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.authState = authState;
        self.authState.stateChangeDelegate = self;
    }
    return self;
}

- (void)getAccessTokenWithCompletionBlock:(PanBaiduNetdiskAccessTokenGetBlock)completion{
    PanBaiduNetdiskAccessToken *token = self.authState.token;
    NSError *tokenUpdateError = token.tokenUpdateError;
    NSDate *tokenExpireDate = token.tokenExpireDate;
    
    BOOL tokenExpired = NO;
    if (tokenExpireDate) {
        tokenExpired = (NSOrderedDescending == [[NSDate date] compare:tokenExpireDate]);
    }
    
    if (tokenExpired) {
        if (completion){
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeAccessTokenExpired]);
        }
        return;
    }
    
    if (tokenUpdateError) {
        NSError *tokenUpdateErrorExternal = [NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeAccessTokenInvalid internalError:tokenUpdateError];
        if (completion){
            completion(nil,tokenUpdateErrorExternal);
        }
        return;
    }
    
    if (token == nil) {
        if (completion){
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetAccessToken]);
        }
        return;
    }
    
    if (completion){
        completion(token,nil);
    }
}

- (NSURLSessionDataTask * _Nullable)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAccessTokenUpdateBlock)completion{
    return [self.authState updateTokenWithCompletion:completion];
}

- (void)panBaiduNetdiskAuthStateDidChange:(PanBaiduNetdiskAuthState *)state{
    [[NSNotificationCenter defaultCenter] postNotificationName:PanBaiduAppAuthProviderDidChangeState object:self];
}

@end
