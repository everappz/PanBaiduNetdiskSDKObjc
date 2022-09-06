//
//  PanBaiduNetdiskAPIClientCache.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/20/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskAPIClientCache.h"
#import "PanBaiduAppAuthProvider.h"
#import "PanBaiduAppAuthManager.h"
#import "PanBaiduNetdiskAPIClient.h"
#import "PanBaiduNetdiskAuthState.h"

@interface PanBaiduNetdiskAPIClientCache()

@property (nonatomic, strong) NSMutableDictionary<NSString *,PanBaiduAppAuthProvider *> *authProviders;

@property (nonatomic, strong) NSMutableDictionary<NSString *,PanBaiduNetdiskAPIClient *> *apiClients;

@end


@implementation PanBaiduNetdiskAPIClientCache

+ (instancetype)sharedCache{
    static dispatch_once_t onceToken;
    static PanBaiduNetdiskAPIClientCache *sharedCache;
    dispatch_once(&onceToken, ^{
        sharedCache = [[PanBaiduNetdiskAPIClientCache alloc] init];
    });
    return sharedCache;
}

- (instancetype)init{
    self = [super init];
    if(self){
        self.authProviders = [[NSMutableDictionary<NSString *,PanBaiduAppAuthProvider *> alloc] init];
        self.apiClients = [[NSMutableDictionary<NSString *,PanBaiduNetdiskAPIClient *> alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(authProviderDidChangeNotification:)
                                                     name:PanBaiduAppAuthProviderDidChangeState
                                                   object:nil];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (PanBaiduNetdiskAPIClient *_Nullable)clientForIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(identifier);
    if (identifier == nil){
        return nil;
    }
    PanBaiduNetdiskAPIClient *client = nil;
    @synchronized (self.apiClients) {
        client = [self.apiClients objectForKey:identifier];
    }
    return client;
}

- (PanBaiduAppAuthProvider *_Nullable)authProviderForIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(identifier);
    if (identifier == nil){
        return nil;
    }
    PanBaiduAppAuthProvider *authProvider = nil;
    @synchronized (self.authProviders) {
        authProvider = [self.authProviders objectForKey:identifier];
    }
    return authProvider;
}

- (BOOL)setAuthProvider:(PanBaiduAppAuthProvider * _Nonnull)authProvider
          forIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(authProvider);
    NSParameterAssert(identifier);
    if (identifier == nil){
        return NO;
    }
    if (authProvider == nil){
        return NO;
    }
    @synchronized (self.authProviders) {
        [self.authProviders setObject:authProvider forKey:identifier];
    }
    return YES;
}

- (BOOL)setClient:(PanBaiduNetdiskAPIClient * _Nonnull)client
    forIdentifier:(NSString * _Nonnull)identifier{
    NSParameterAssert(client);
    NSParameterAssert(identifier);
    if (identifier == nil){
        return NO;
    }
    if (client == nil){
        return NO;
    }
    @synchronized (self.apiClients) {
        [self.apiClients setObject:client forKey:identifier];
    }
    return YES;
}

- (PanBaiduNetdiskAPIClient *_Nullable)createClientForIdentifier:(NSString *_Nonnull)identifier
                                                       authState:(PanBaiduNetdiskAuthState *_Nonnull)authState
                                            sessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
{
    
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    
    if(identifier == nil || authState == nil){
        return nil;
    }
    
    PanBaiduAppAuthProvider *authProvider = [self authProviderForIdentifier:identifier];
    if (authProvider == nil) {
        authProvider = [[PanBaiduAppAuthProvider alloc] initWithIdentifier:identifier
                                                                     state:authState];
        if (authProvider) {
            [self setAuthProvider:authProvider forIdentifier:identifier];
        }
    }
    NSParameterAssert(authProvider);
    if(authProvider == nil){
        return nil;
    }
    
    PanBaiduNetdiskAPIClient *client = [[PanBaiduNetdiskAPIClient alloc] initWithURLSessionConfiguration:URLSessionConfiguration
                                                                                            authProvider:authProvider];
    NSParameterAssert(client);
    if(client){
        [self setClient:client forIdentifier:identifier];
    }
    return client;
}

- (void)updateAuthState:(PanBaiduNetdiskAuthState *_Nonnull)authState
          forIdentifier:(NSString *_Nonnull)identifier{
    NSParameterAssert(authState);
    NSParameterAssert(identifier);
    if(authState == nil || identifier == nil){
        return;
    }
    NSLog(@"authStateChanged: %@ forIdentifier: %@",authState.accessToken,identifier);
    PanBaiduAppAuthProvider *authProvider = [[PanBaiduAppAuthProvider alloc] initWithIdentifier:identifier
                                                                                          state:authState];
    NSParameterAssert(authProvider);
    if(authProvider){
        [self setAuthProvider:authProvider forIdentifier:identifier];
    }
    PanBaiduNetdiskAPIClient *apiClient = [self clientForIdentifier:identifier];
    NSParameterAssert(apiClient);
    [apiClient updateAuthProvider:authProvider];
}

- (void)authProviderDidChangeNotification:(NSNotification *)notification{
    PanBaiduAppAuthProvider *provider = notification.object;
    NSParameterAssert([provider isKindOfClass:[PanBaiduAppAuthProvider class]]);
    if([provider isKindOfClass:[PanBaiduAppAuthProvider class]]){
        NSLog(@"authProviderDidChangeNotification: %@ forIdentifier: %@",provider.authState.accessToken,provider.identifier);
    }
}

@end
