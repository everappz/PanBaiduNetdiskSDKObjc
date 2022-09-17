//
//  PanBaiduNetdiskAPIClient.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <CommonCrypto/CommonDigest.h>
#import "PanBaiduNetdiskAPIClient.h"
#import "PanBaiduNetdiskConstants.h"
#import "PanBaiduAppAuthProvider.h"
#import "NSError+PanBaiduNetdisk.h"
#import "PanBaiduNetdiskFile.h"
#import "PanBaiduNetdiskUser.h"
#import "PanBaiduNetdiskNetworkClient.h"
#import "PanBaiduNetdiskAPIClientRequest.h"
#import "PanBaiduNetdiskRequestsCache.h"
#import "PanBaiduNetdiskAccessToken.h"
#import "PanBaiduNetdiskAPIClientCache.h"
#import "PanBaiduNetdiskAuthState.h"

#define PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest) if (weak_clientRequest == nil || weak_clientRequest.isCancelled){ return; }

NSTimeInterval const kBNDAPIClientRequestRetryTimeout = 2.0;

@interface PanBaiduNetdiskAPIClient()

@property (nonatomic,strong)PanBaiduNetdiskNetworkClient *networkClient;
@property (nonatomic,strong,nullable)PanBaiduAppAuthProvider *authProvider;
@property (nonatomic,strong,nullable)NSRecursiveLock *authProviderLock;

@end


@implementation PanBaiduNetdiskAPIClient

+ (nullable PanBaiduNetdiskAPIClient *)createNewOrGetCachedClientWithAuthData:(NSDictionary *)clientAuthData{
    id dataObj = [clientAuthData objectForKey:PanBaiduNetdiskAccessTokenDataKey];
    NSString *userID = [clientAuthData objectForKey:PanBaiduNetdiskUserIDKey];
    
    NSParameterAssert([dataObj isKindOfClass:[NSData class]]);
    if ([dataObj isKindOfClass:[NSData class]] == NO) {
        return nil;
    }
    
    NSData *authData = (NSData *)dataObj;
    NSParameterAssert(authData.length > 0);
    if (authData.length == 0) {
        return nil;
    }
    
    NSParameterAssert(userID.length > 0);
    if (userID.length == 0) {
        return nil;
    }
    
    id unarchivedObject = nil;
    if (@available(iOS 11.0, *)) {
        unarchivedObject = [NSKeyedUnarchiver unarchivedObjectOfClass:[PanBaiduNetdiskAccessToken class] fromData:authData error:nil];
    } else {
        unarchivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:authData];
    }
    
    NSParameterAssert([unarchivedObject isKindOfClass:[PanBaiduNetdiskAccessToken class]]);
    if ([unarchivedObject isKindOfClass:[PanBaiduNetdiskAccessToken class]] == NO) {
        return nil;
    }
    
    PanBaiduNetdiskAuthState *authState = [[PanBaiduNetdiskAuthState alloc] initWithToken:unarchivedObject];
    PanBaiduNetdiskAPIClient *apiClient = [[PanBaiduNetdiskAPIClientCache sharedCache] clientForIdentifier:userID];
    if (apiClient == nil) {
        apiClient = [[PanBaiduNetdiskAPIClientCache sharedCache] createClientForIdentifier:userID
                                                                                 authState:authState
                                                                      sessionConfiguration:nil];
    }
    
    return apiClient;
}

- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
                                   authProvider:(PanBaiduAppAuthProvider *_Nullable)authProvider
{
    self = [super init];
    if (self) {
        self.authProvider = authProvider;
        self.authProviderLock = [NSRecursiveLock new];
        self.networkClient = [[PanBaiduNetdiskNetworkClient alloc] initWithURLSessionConfiguration:URLSessionConfiguration];
    }
    return self;
}

- (void)cancelAllRequests{
    [self cancelAndRemoveAllCachedRequests];
}

#pragma mark - Access Token

- (void)updateAuthProvider:(PanBaiduAppAuthProvider *_Nullable)authProvider{
    [self.authProviderLock lock];
    self.authProvider = authProvider;
    [self.authProviderLock unlock];
}

- (void)getAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientAccessTokenBlock _Nullable)completion{
    PanBaiduAppAuthProvider *authProvider = nil;
    [self.authProviderLock lock];
    authProvider = self.authProvider;
    [self.authProviderLock unlock];
    
    NSParameterAssert(authProvider);
    if (authProvider) {
        [authProvider getAccessTokenWithCompletionBlock:completion];
        return;
    }
    
    if (completion) {
        completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeAuthProviderIsNil]);
    }
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientVoidBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduAppAuthProvider *authProvider = nil;
    [self.authProviderLock lock];
    authProvider = self.authProvider;
    [self.authProviderLock unlock];
    
    NSParameterAssert(authProvider);
    if (authProvider) {
        NSURLSessionDataTask *task =
        [authProvider updateAccessTokenWithCompletionBlock:^(NSString * _Nullable accessToken, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            
            if (completion) {
                completion();
            }
        }];
        clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
        return clientRequest;
    }
    
    [self removeCancellableRequestFromCache:clientRequest];
    if (completion) {
        completion();
    }
    return nil;
}

#pragma mark - User Info

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion) {
            completion(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [strongSelf _getUserInfoWithCompletionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error)
     {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponse:nil
                                                 withData:nil
                                                    error:error
                                               completion:completion];
            return;
        }
        
        NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:@{@"method":@"uinfo"} inURL:kPanBaiduNetdiskNasURL];
        NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
        [PanBaiduNetdiskNetworkClient printRequest:request];
        
        NSURLSessionDataTask *task =
        [strongSelf dataTaskWithRequest:request
                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponse:response
                                                 withData:data
                                                    error:error
                                               completion:completion];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
        [task resume];
    }];
    
    return clientRequest;
}

#pragma mark - Files List

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFilesListAtPath:(nullable NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientArrayBlock _Nullable)completion
{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientArrayBlock resultCompletion = ^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(array,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            weak_clientRequest.internalRequest = [strongSelf _getFilesListAtPath:path completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _getFilesListAtPath:path
                                                                        completionBlock:^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(array,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_getFilesListAtPath:(nullable NSString *)path
                                                                completionBlock:(PanBaiduNetdiskAPIClientArrayBlock _Nullable)completion
{
    NSMutableArray *resultFiles = [NSMutableArray new];
    
    //The number of queries defaults to 1000, and it is recommended that the maximum number should not exceed 1000.
    return [self _getFilesListAtPath:path offset:0 length:1000 resultFiles:resultFiles completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_getFilesListAtPath:(nullable NSString *)path
                                                                         offset:(NSInteger)offset
                                                                         length:(NSInteger)length
                                                                    resultFiles:(NSMutableArray *)resultFiles
                                                                completionBlock:(PanBaiduNetdiskAPIClientArrayBlock _Nullable)completion
{
    NSParameterAssert(resultFiles);
    if (resultFiles == nil) {
        if(completion){
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            if (completion) {
                completion(nil,error);
            }
            return;
        }
        
        NSString *pathModified = (path != nil)?path:@"/";
        NSDictionary *parameters = @{
            @"method":@"list",
            @"start":[NSString stringWithFormat:@"%@",@(offset)],
            @"limit":[NSString stringWithFormat:@"%@",@(length)],
            @"dir":pathModified
        };
        NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:parameters inURL:kPanBaiduNetdiskFileURL];
        NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
        [PanBaiduNetdiskNetworkClient printRequest:request];
        
        NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            [PanBaiduNetdiskNetworkClient processResponse:response
                                                 withData:data
                                                    error:error
                                               completion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                NSArray *responseArray = nil;
                if([dictionary isKindOfClass:[NSDictionary class]] && [dictionary objectForKey:@"list"]){
                    responseArray = [dictionary objectForKey:@"list"];
                }
                if(responseArray.count>0){
                    [resultFiles addObjectsFromArray:responseArray];
                }
                BOOL loadNext = responseArray.count >= length;
                if (loadNext) {
                    id<PanBaiduNetdiskAPIClientCancellableRequest> nextPageRequest = [strongSelf _getFilesListAtPath:path
                                                                                                              offset:offset+length
                                                                                                              length:length
                                                                                                         resultFiles:resultFiles
                                                                                                     completionBlock:completion];
                    weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)nextPageRequest;
                }
                else {
                    [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                    if (resultFiles.count == 0 || error) {
                        if(completion){
                            completion(nil,error);
                        }
                    }
                    else {
                        if (completion) {
                            completion(resultFiles,nil);
                        }
                    }
                }
            }];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
        [task resume];
    }];
    
    return clientRequest;
}

#pragma mark - File Info

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getInfoForFileWithID:(NSString *)fileID
                                                                           dlink:(BOOL)dlink
                                                                           thumb:(BOOL)thumb
                                                                           extra:(BOOL)extra
                                                                       needmedia:(BOOL)needmedia
                                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            
            weak_clientRequest.internalRequest = [strongSelf _getInfoForFileWithID:fileID
                                                                             dlink:dlink
                                                                             thumb:thumb
                                                                             extra:extra
                                                                         needmedia:needmedia
                                                                   completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _getInfoForFileWithID:fileID
                                                                                    dlink:dlink
                                                                                    thumb:thumb
                                                                                    extra:extra
                                                                                needmedia:needmedia
                                                                          completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_getInfoForFileWithID:(NSString *)fileID
                                                                            dlink:(BOOL)dlink
                                                                            thumb:(BOOL)thumb
                                                                            extra:(BOOL)extra
                                                                        needmedia:(BOOL)needmedia
                                                                  completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponse:nil
                                                 withData:nil
                                                    error:error
                                               completion:completion];
            return;
        }
        
        
        NSMutableDictionary *params = [@{@"method":@"filemetas",@"fsids":[NSString stringWithFormat:@"[%@]",fileID]} mutableCopy];
        if (dlink) {
            [params setObject:@"1" forKey:@"dlink"];
        }
        if (thumb) {
            [params setObject:@"1" forKey:@"thumb"];
        }
        if (extra) {
            [params setObject:@"1" forKey:@"extra"];
        }
        if (needmedia) {
            [params setObject:@"1" forKey:@"needmedia"];
        }
        NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:params inURL:kPanBaiduNetdiskMultimediaURL];
        NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
        [PanBaiduNetdiskNetworkClient printRequest:request];
        
        NSURLSessionDataTask *task =
        [strongSelf dataTaskWithRequest:request
                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            
            [PanBaiduNetdiskNetworkClient processResponse:response
                                                 withData:data
                                                    error:error
                                               completion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                NSArray *responseArray = nil;
                if ([dictionary isKindOfClass:[NSDictionary class]] && [dictionary objectForKey:@"list"]) {
                    responseArray = [dictionary objectForKey:@"list"];
                }
                if (completion) {
                    completion(responseArray.lastObject,error);
                }
            }];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
        [task resume];
    }];
    return clientRequest;
}

#pragma mark - Create Folder Request

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)createFolderAtPath:(NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    return [self _fileCreateRequestWithPath:path
                                       size:0
                                      isDir:YES
                                  blockList:nil
                                   uploadId:nil
                             renamingPolicy:1
                                 isRevision:NO
                            completionBlock:completion];
}

#pragma mark - File Manager Request

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)deleteFileAtPath:(NSString *)filePath
                                                             completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(filePath);
    if (filePath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    return [self _defaultFileManagerRequestWithMethod:@"delete"
                                            overwrite:NO
                                   fileListParameters:@{@"path":filePath}
                                      completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)renameFileAtPath:(NSString *)filePath
                                                                        name:(NSString *)name
                                                             completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(filePath);
    if (filePath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSParameterAssert(name);
    if (name == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    return [self _defaultFileManagerRequestWithMethod:@"rename"
                                            overwrite:NO
                                   fileListParameters:@{@"path":filePath,@"newname":name}
                                      completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)moveFileAtPath:(NSString *)filePath
                                                                    toPath:(NSString *)toPath
                                                           completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(filePath);
    if (filePath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSParameterAssert(toPath);
    if (toPath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    return [self _defaultFileManagerRequestWithMethod:@"move"
                                            overwrite:NO
                                   fileListParameters:@{@"path":filePath,@"dest":toPath.stringByDeletingLastPathComponent,@"newname":toPath.lastPathComponent} completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)copyFileAtPath:(NSString *)filePath
                                                                    toPath:(NSString *)toPath
                                                           completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(filePath);
    if (filePath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSParameterAssert(toPath);
    if (toPath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    return [self _defaultFileManagerRequestWithMethod:@"copy"
                                            overwrite:NO
                                   fileListParameters:@{@"path":filePath,@"dest":toPath.stringByDeletingLastPathComponent,@"newname":toPath.lastPathComponent} completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_defaultFileManagerRequestWithMethod:(NSString *)method
                                                                                       overwrite:(BOOL)overwrite
                                                                              fileListParameters:(NSDictionary<NSString *,NSString *> *)fileListParameters
                                                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(method);
    if (method == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSMutableDictionary *bodyParameters = [NSMutableDictionary new];
    
    //0 synchronization, 1 adaptive, 2 asynchronous
    [bodyParameters setObject:@(0) forKey:@"async"];
    
    // Global ondup, handling strategy for duplicate files, fail (default, return directly to failure), newcopy, overwrite, skip
    if (overwrite) {
        [bodyParameters setObject:@"overwrite" forKey:@"ondup"];
    }
    
    NSMutableDictionary *fileListDictionary = [NSMutableDictionary new];
    [fileListParameters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *encodedObj = [PanBaiduNetdiskNetworkClient URLEncodedPath:obj];
        [fileListDictionary setObject:encodedObj forKey:key];
    }];
    
    NSArray *fileListArr = @[fileListDictionary];
    NSError *jsonSerializationError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fileListArr options:0 error:&jsonSerializationError];
    
    if (jsonSerializationError) {
        NSError *resultError = [NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotPrepareRequest internalError:jsonSerializationError];
        if (completion) {
            completion(nil,resultError);
        }
        return nil;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [bodyParameters setObject:jsonString forKey:@"filelist"];
    
    return [self _fileManagerRequestWithMethod:method
                                bodyParameters:bodyParameters
                               completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_fileManagerRequestWithMethod:(NSString *)fileManagerMethod
                                                                           bodyParameters:(NSDictionary<NSString *,NSString *> *)bodyParameters
                                                                          completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(fileManagerMethod);
    if (fileManagerMethod == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(dictionary,error);
        }
    };
    
    NSString *requestMethod = @"filemanager";
    NSDictionary *urlParameters = @{@"opera":fileManagerMethod};
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            
            weak_clientRequest.internalRequest = [strongSelf _fileRequestWithMethod:requestMethod
                                                                      urlParameters:urlParameters
                                                                     bodyParameters:bodyParameters
                                                                    completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _fileRequestWithMethod:requestMethod
                                                                             urlParameters:urlParameters
                                                                            bodyParameters:bodyParameters
                                                                           completionBlock:^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

#pragma mark - Download File

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getContentForFileWithID:(NSString *)fileID
                                                                  additionalHeaders:(NSDictionary *)additionalHeaders
                                                                didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                                            didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                                    completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (completion) {
            completion([NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientErrorBlock resultCompletion = ^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            
            weak_clientRequest.internalRequest = [strongSelf getContentForFileWithID:fileID
                                                                   additionalHeaders:additionalHeaders
                                                                 didReceiveDataBlock:didReceiveData
                                                             didReceiveResponseBlock:didReceiveResponse
                                                                     completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _getContentForFileWithID:fileID
                                                                           additionalHeaders:additionalHeaders
                                                                         didReceiveDataBlock:didReceiveData
                                                                     didReceiveResponseBlock:didReceiveResponse
                                                                             completionBlock:^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_getContentForFileWithID:(NSString *)fileID
                                                                   additionalHeaders:(NSDictionary *)additionalHeaders
                                                                 didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                                             didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                                     completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (completion) {
            completion([NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    clientRequest.didReceiveDataBlock = didReceiveData;
    clientRequest.didReceiveResponseBlock = didReceiveResponse;
    clientRequest.errorCompletionBlock = completion;
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskMakeWeakSelf;
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponse:nil
                                                withError:error
                                               completion:completion];
            return;
        }
        
        id<PanBaiduNetdiskAPIClientCancellableRequest> fileInfoRequest =
        [strongSelf _getInfoForFileWithID:fileID
                                    dlink:YES
                                    thumb:NO
                                    extra:NO
                                needmedia:NO
                          completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            NSString *dlink = [dictionary objectForKey:@"dlink"];
            NSURL *downloadURL = nil;
            if (dlink.length > 0) {
                downloadURL = [NSURL URLWithString:dlink];
            }
            
            if (error) {
                [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processResponse:nil
                                                    withError:error
                                                   completion:completion];
            }
            else if (downloadURL == nil) {
                [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processResponse:nil
                                                    withError:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetDirectURL]
                                                   completion:completion];
            }
            else {
                NSURL *requestURL = downloadURL;
                NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
                [PanBaiduNetdiskNetworkClient printRequest:request];
                [additionalHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [request setValue:obj forHTTPHeaderField:key];
                }];
                
                NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request];
                weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
                weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
                [PanBaiduNetdiskNetworkClient printRequest:request];
                [task resume];
            }
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)fileInfoRequest;
    }];
    
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getDirectURLForFileWithID:(NSString *)fileID
                                                                      completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)completion
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientURLBlock resultCompletion = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(location,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            
            weak_clientRequest.internalRequest = [strongSelf _getDirectURLForFileWithID:fileID
                                                                        completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _getDirectURLForFileWithID:fileID
                                                                               completionBlock:^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(location,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_getDirectURLForFileWithID:(NSString *)fileID
                                                                       completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)completion
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponseWithURL:nil
                                                           error:error
                                                      completion:completion];
            return;
        }
        
        id<PanBaiduNetdiskAPIClientCancellableRequest> fileInfoRequest =
        [strongSelf _getInfoForFileWithID:fileID
                                    dlink:YES
                                    thumb:NO
                                    extra:NO
                                needmedia:NO
                          completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            
            NSString *dlink = [dictionary objectForKey:@"dlink"];
            NSURL *downloadURL = nil;
            if (dlink.length > 0) {
                downloadURL = [NSURL URLWithString:dlink];
            }
            
            if (error) {
                [PanBaiduNetdiskNetworkClient processResponseWithURL:nil
                                                               error:error
                                                          completion:completion];
                return;
            }
            
            if (downloadURL == nil) {
                [PanBaiduNetdiskNetworkClient processResponseWithURL:nil
                                                               error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetDirectURL]
                                                          completion:completion];
                return;
            }
            
            NSURL *requestURL = downloadURL;
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
            [PanBaiduNetdiskNetworkClient printRequest:request];
            NSURL *requestURLWithAuth = request.URL;
            NSError *resultError = (requestURLWithAuth == nil)?[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetDirectURL]:nil;
            [PanBaiduNetdiskNetworkClient processResponseWithURL:requestURLWithAuth
                                                           error:resultError
                                                      completion:completion];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)fileInfoRequest;
    }];
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)downloadContentForFileWithID:(NSString *)fileID
                                                                           progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                         completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)downloadCompletionBlock
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (downloadCompletionBlock) {
            downloadCompletionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientURLBlock resultCompletion = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (downloadCompletionBlock) {
            downloadCompletionBlock(location,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            
            weak_clientRequest.internalRequest = [strongSelf _downloadContentForFileWithID:fileID
                                                                             progressBlock:progressBlock
                                                                           completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _downloadContentForFileWithID:fileID
                                                                                    progressBlock:progressBlock
                                                                                  completionBlock:^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(location,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_downloadContentForFileWithID:(NSString *)fileID
                                                                            progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                          completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)downloadCompletionBlock
{
    NSParameterAssert(fileID);
    if (fileID == nil) {
        if (downloadCompletionBlock) {
            downloadCompletionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskMakeWeakSelf;
    clientRequest.progressBlock = progressBlock;
    
    clientRequest.downloadCompletionBlock = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (downloadCompletionBlock) {
            downloadCompletionBlock(location,error);
        }
    };
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponseWithURL:nil
                                                           error:error
                                                      completion:downloadCompletionBlock];
            return;
        }
        
        id<PanBaiduNetdiskAPIClientCancellableRequest> fileInfoRequest =
        [strongSelf _getInfoForFileWithID:fileID
                                    dlink:YES
                                    thumb:NO
                                    extra:NO
                                needmedia:NO
                          completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            
            NSString *dlink = [dictionary objectForKey:@"dlink"];
            NSURL *downloadURL = nil;
            if (dlink.length > 0) {
                downloadURL = [NSURL URLWithString:dlink];
            }
            
            if (error) {
                [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processResponseWithURL:nil
                                                               error:error
                                                          completion:downloadCompletionBlock];
                return;
            }
            
            if (downloadURL == nil) {
                [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processResponseWithURL:nil
                                                               error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetDirectURL]
                                                          completion:downloadCompletionBlock];
                return;
            }
            
            NSURL *requestURL = downloadURL;
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
            [PanBaiduNetdiskNetworkClient printRequest:request];
            
            NSURLSessionDownloadTask *task = [strongSelf downloadTaskWithRequest:request];
            weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
            [task resume];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)fileInfoRequest;
    }];
    
    return clientRequest;
}

#pragma mark - Upload File

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)uploadFileFromLocalPath:(NSString *)localPath
                                                                       toRemotePath:(NSString *)remotePath
                                                                      progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                    completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completionBlock
{
    NSParameterAssert(localPath);
    if (localPath == nil) {
        if (completionBlock) {
            completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSParameterAssert(remotePath);
    if (remotePath == nil) {
        if (completionBlock) {
            completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completionBlock){
            completionBlock(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest =
            [weakSelf _uploadFileFromLocalPath:localPath
                                  toRemotePath:remotePath
                                 progressBlock:progressBlock
                               completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _uploadFileFromLocalPath:localPath
                                                                                toRemotePath:remotePath
                                                                               progressBlock:progressBlock
                                                                             completionBlock:^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_uploadFileFromLocalPath:(NSString *)localPath
                                                                        toRemotePath:(NSString *)remotePath
                                                                       progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                     completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completionBlock
{
    NSParameterAssert(localPath);
    if (localPath == nil) {
        if (completionBlock) {
            completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSParameterAssert(remotePath);
    if (remotePath == nil) {
        if (completionBlock) {
            completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath] == NO) {
        if (completionBlock) {
            completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeLocalFileNotFound]);
        }
        return nil;
    }
    
    unsigned long long contentSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil] fileSize];
    if (contentSize == 0 || contentSize == -1) {
        if (completionBlock) {
            completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeLocalFileEmpty]);
        }
        
        return nil;
    }
    
    const NSUInteger kBlockSize = 4 * 1024 * 1024; //4MB
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    clientRequest.totalContentSize = @(contentSize);
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponse:nil
                                                 withData:nil
                                                    error:error
                                               completion:completionBlock];
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSMutableArray<NSString *> *blockList = [NSMutableArray<NSString *> new];
            
            @autoreleasepool {
                NSFileHandle *fileHandle = nil;
                BOOL fileReadError = NO;
                @try {
                    fileHandle = [NSFileHandle fileHandleForReadingAtPath:localPath];
                    NSUInteger fileOffset = 0;
                    while (fileOffset < contentSize) {
                        [fileHandle seekToFileOffset:fileOffset];
                        NSData *chunkData = [fileHandle readDataOfLength:kBlockSize];
                        NSString *chunkMD5 = [PanBaiduNetdiskAPIClient MD5ForSmallData:chunkData];
                        NSCParameterAssert(chunkMD5.length > 0);
                        if (chunkMD5.length > 0) {
                            [blockList addObject:chunkMD5];
                        }
                        else {
                            fileReadError = YES;
                            break;
                        }
                        fileOffset += chunkData.length;
                    }
                } @catch (NSException *exception) {
                    fileReadError = YES;
                } @finally {
                    [fileHandle closeFile];
                }
                
                if (fileReadError) {
                    if (completionBlock) {
                        completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotPrepareRequest]);
                    }
                    return;
                }
            }
            
            const NSUInteger renamingPolicy = 3;//3 Override the file with the same name when there is a file in the cloud.
            
            id<PanBaiduNetdiskAPIClientCancellableRequest> preUploadRequest =
            [strongSelf _filePreCreateRequestWithPath:remotePath
                                                 size:contentSize
                                                isDir:NO
                                            blockList:blockList
                                       renamingPolicy:renamingPolicy
                                      completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                
                PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
                
                if (error) {
                    [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                    if (completionBlock) {
                        completionBlock(nil,error);
                    }
                    return;
                }
                
                NSString *uploadID = [dictionary objectForKey:@"uploadid"];
                
                if (uploadID == nil) {
                    [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                    if (completionBlock) {
                        completionBlock(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadResponse]);
                    }
                    return;
                }
                
                [strongSelf _uploadNextChunkForFileAtLocalPath:localPath
                                                    remotePath:remotePath
                                                      uploadID:uploadID
                                                    partNumber:0
                                                   contentSize:contentSize
                                                     blockSize:kBlockSize
                                                     blockList:blockList
                                                 clientRequest:weak_clientRequest
                                                 progressBlock:progressBlock
                                               completionBlock:^(NSError * _Nullable error) {
                    if (error) {
                        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                        if (completionBlock) {
                            completionBlock(nil,error);
                        }
                        return;
                    }
                    
                    id<PanBaiduNetdiskAPIClientCancellableRequest> createFileRequest =
                    [strongSelf _fileCreateRequestWithPath:remotePath
                                                      size:contentSize
                                                     isDir:NO
                                                 blockList:blockList
                                                  uploadId:uploadID
                                            renamingPolicy:renamingPolicy
                                                isRevision:YES
                                           completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
                        if (completionBlock) {
                            completionBlock(dictionary,error);
                        }
                    }];
                    
                    weak_clientRequest.internalRequest = createFileRequest;
                }];
            }];
            
            weak_clientRequest.internalRequest = preUploadRequest;
        });
        
    }];
    
    return clientRequest;
}

- (void)_uploadNextChunkForFileAtLocalPath:(NSString *)localPath
                                remotePath:(NSString *)remotePath
                                  uploadID:(NSString *)uploadID
                                partNumber:(NSUInteger)partNumber
                               contentSize:(unsigned long long)contentSize
                                 blockSize:(NSUInteger)blockSize
                                 blockList:(NSArray<NSString *> *)blockList
                             clientRequest:(PanBaiduNetdiskAPIClientRequest *)clientRequest
                             progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                           completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completionBlock
{
    NSParameterAssert(localPath != nil &&
                      remotePath != nil &&
                      uploadID != nil &&
                      contentSize > 0 &&
                      blockList.count > 0);
    
    if (localPath == nil ||
        remotePath == nil ||
        uploadID == nil ||
        contentSize == 0 ||
        blockList.count == 0)
    {
        if (completionBlock) {
            completionBlock([NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return;
    }
    
    if (partNumber >= blockList.count) {
        //file uploaded successfully
        if (completionBlock) {
            completionBlock(nil);
        }
        return;
    }
    
    NSData *chunkData = nil;
    NSUInteger chunkDataLength = 0;
    NSFileHandle *fileHandle = nil;
    
    @try {
        fileHandle = [NSFileHandle fileHandleForReadingAtPath:localPath];
        const NSUInteger fileOffset = partNumber * blockSize;
        [fileHandle seekToFileOffset:fileOffset];
        chunkData = [fileHandle readDataOfLength:blockSize];
        chunkDataLength = chunkData.length;
    } @catch (NSException *exception) {
        chunkData = nil;
        chunkDataLength = 0;
    }
    @finally {
        [fileHandle closeFile];
    }
    
    NSParameterAssert(chunkDataLength);
    if (chunkDataLength == 0) {
        if (completionBlock) {
            completionBlock([NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotPrepareRequest]);
        }
        return;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> chunkUploadRequest =
    [self _fileUploadChunkRequestWithPath:remotePath
                                 uploadId:uploadID
                               partNumber:partNumber
                                 fileData:chunkData
                            progressBlock:^(float chunkProgress) {
        
        const NSUInteger transferredDataLengthInPreviousRequests = partNumber > 0 ? (partNumber * blockSize) : 0;
        const NSUInteger transferredDataLengthInCurrentRequest = chunkDataLength * chunkProgress;
        const NSUInteger totalTransferredDataLength = transferredDataLengthInPreviousRequests + transferredDataLengthInCurrentRequest;
        
        const float totalProgress = (float)totalTransferredDataLength/(float)contentSize;
        if (progressBlock) {
            progressBlock(totalProgress);
        }
    }
                          completionBlock:^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            if (completionBlock) {
                completionBlock(error);
            }
            return;
        }
        
        [weakSelf _uploadNextChunkForFileAtLocalPath:localPath
                                          remotePath:remotePath
                                            uploadID:uploadID
                                          partNumber:partNumber+1
                                         contentSize:contentSize
                                           blockSize:blockSize
                                           blockList:blockList
                                       clientRequest:weak_clientRequest
                                       progressBlock:progressBlock
                                     completionBlock:completionBlock];
    }];
    
    clientRequest.internalRequest = chunkUploadRequest;
}

#pragma mark - File Upload Chunk Request

/**
 @param filePath The absolute path of the files used after upload requires urlencode, which needs to be consistent with the path in the pre-upload interface.
 @param uploadId Uploadid sent under the precreate interface
 @param partNumber The location or serial number of the file shard, starting from 0, refer to the block_list returned by the precreate interface pre-upload in the previous stage..
 @param fileData Uploaded File Content
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_fileUploadChunkRequestWithPath:(NSString *)filePath
                                                                                   uploadId:(NSString *)uploadId
                                                                                 partNumber:(NSUInteger)partNumber
                                                                                   fileData:(NSData *)fileData
                                                                              progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                            completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion
{
    NSParameterAssert(filePath);
    if (filePath == nil) {
        if (completion) {
            completion([NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSParameterAssert(uploadId);
    if (uploadId == nil) {
        if (completion) {
            completion([NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSParameterAssert(fileData);
    if (fileData == nil) {
        if (completion) {
            completion([NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSMutableDictionary *urlParameters = [NSMutableDictionary new];
    [urlParameters setObject:[NSString stringWithFormat:@"%@",@(partNumber)] forKey:@"partseq"];
    [urlParameters setObject:filePath forKey:@"path"];
    
    NSString *fileName = filePath.lastPathComponent;
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            weak_clientRequest.internalRequest = [strongSelf _fileUploadChunkRequestWithUploadId:uploadId
                                                                                   urlParameters:urlParameters
                                                                                        fileData:fileData
                                                                                        fileName:fileName
                                                                                   progressBlock:progressBlock
                                                                                 completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _fileUploadChunkRequestWithUploadId:uploadId
                                                                                          urlParameters:urlParameters
                                                                                               fileData:fileData
                                                                                               fileName:fileName
                                                                                          progressBlock:progressBlock
                                                                                        completionBlock:^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_fileUploadChunkRequestWithUploadId:(NSString *)uploadId
                                                                                  urlParameters:(NSDictionary<NSString *,NSString *> *)urlParameters
                                                                                       fileData:(NSData *)fileData
                                                                                       fileName:(NSString *)fileName
                                                                                  progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                                completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(uploadId);
    NSParameterAssert(urlParameters);
    NSParameterAssert(fileData);
    NSParameterAssert(fileName);
    
    if (uploadId == nil ||
        urlParameters == nil ||
        fileData == nil ||
        fileName == nil)
    {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    clientRequest.progressBlock = progressBlock;
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskMakeWeakReference(clientRequest)
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponse:nil
                                                 withData:nil
                                                    error:error
                                               completion:completion];
            return;
        }
        
        NSMutableDictionary *urlQueryParameters = [@{@"method":@"upload"} mutableCopy];
        if (urlParameters) {
            [urlQueryParameters addEntriesFromDictionary:urlParameters];
        }
        
        NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:urlQueryParameters inURL:kPanBaiduNetdiskSuperFileURL];
        
        //add uploadid to skip url encoding in URLByReplacingQueryParameters
        requestURL = [NSURL URLWithString:[requestURL.absoluteString stringByAppendingFormat:@"&uploadid=%@",uploadId]];
        
        NSString *mimeType = [PanBaiduNetdiskAPIClient extensionToMIMEType:fileName.pathExtension.lowercaseString];
        NSString *boundary = [PanBaiduNetdiskNetworkClient createMultipartFormBoundary];
        NSString *charset = @"utf-8";
        NSString *contentType = [NSString stringWithFormat:@"%@; charset=%@; boundary=%@",kPanBaiduNetdiskContentTypeMultipartFormData, charset, boundary];
        
        NSMutableURLRequest *request = [strongSelf POSTRequestWithURL:requestURL
                                                          contentType:contentType
                                                          accessToken:accessToken];
        
        NSData *requestHTTPBodyData = [PanBaiduNetdiskNetworkClient createMultipartFormDataBodyWithBoundary:boundary
                                                                                              parameterName:@"file"
                                                                                                   fileName:fileName
                                                                                                   fileData:fileData
                                                                                                   mimeType:mimeType];
        [request setHTTPBody:requestHTTPBodyData];
        
        [request addValue:[NSString stringWithFormat:@"%@",@(requestHTTPBodyData.length)] forHTTPHeaderField:@"Content-Length"];
        [PanBaiduNetdiskNetworkClient printRequest:request];
        
        NSURLSessionDataTask *task = [strongSelf uploadTaskWithRequest:request
                                                              fromData:requestHTTPBodyData
                                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            
            [PanBaiduNetdiskNetworkClient processResponse:response
                                                 withData:data
                                                    error:error
                                               completion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                if (completion) {
                    completion(dictionary,error);
                }
            }];
        }];
        weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
        [task resume];
    }];
    return clientRequest;
}


#pragma mark - File Create Request

/**
 @param filePath The absolute path of the files used after upload requires urlencode, which needs to be consistent with the path in the pre-upload interface.
 @param size The size of the file or directory must be consistent with the real size of the file, and it needs to be consistent with the size in the pre-upload precreate interface.
 @param isDir Whether the directory, 0 file, 1 directory needs to be consistent with isdir in the pre-upload precreate interface.
 @param blockList The json string of the shard md5 array of files It needs to be consistent with the block_list in the precreate interface, and the md5 returned by the shard upload superfile2 interface should be arranged in order to form the json string of the md5 array.  ["98d02a0f54781a93e354b1fc85caf488", "ca5273571daefb8ea01a42bfa5d02220"]
 @param uploadId Uploadid sent under the precreate interface
 @param renamingPolicy File naming policy, default 0 0 is not renamed, return conflict 1 Rename as long as the path conflicts 2 Rename the path conflict and block_list is different. 3 For coverage, it needs to be consistent with the rtype in the pre-upload precreate interface.
 @param isRevision Do you need multi-version support? 1 is supported, 0 is not supported, and the default is 0 (with this parameter, the renaming policy will be ignored)
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_fileCreateRequestWithPath:(NSString *)filePath
                                                                                  size:(long long int)size
                                                                                 isDir:(BOOL)isDir
                                                                             blockList:(nullable NSArray<NSString *> *)blockList
                                                                              uploadId:(nullable NSString *)uploadId
                                                                        renamingPolicy:(NSUInteger)renamingPolicy
                                                                            isRevision:(BOOL)isRevision
                                                                       completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(filePath);
    if (filePath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSMutableDictionary *bodyParameters = [NSMutableDictionary new];
    [bodyParameters setObject:@(isRevision) forKey:@"is_revision"];
    [bodyParameters setObject:@(renamingPolicy) forKey:@"rtype"];
    if (uploadId) {
        [bodyParameters setObject:uploadId forKey:@"uploadid"];
    }
    
    if (blockList) {
        NSMutableArray *blockListFixed = [NSMutableArray new];
        for (NSString *item in blockList) {
            [blockListFixed addObject:[NSString stringWithFormat:@"\"%@\"",item]];
        }
        NSString *blockListString = [NSString stringWithFormat:@"[%@]",[blockListFixed componentsJoinedByString:@","]];
        [bodyParameters setObject:blockListString forKey:@"block_list"];
    }
    
    [bodyParameters setObject:@(isDir) forKey:@"isdir"];
    [bodyParameters setObject:@(size) forKey:@"size"];
    
    NSString *encodedPathParameter = [PanBaiduNetdiskNetworkClient URLEncodedParameters:@{@"path":filePath}];
    NSString *encodedPath = [encodedPathParameter componentsSeparatedByString:@"="].lastObject;
    NSParameterAssert(encodedPath);
    if (encodedPath) {
        [bodyParameters setObject:encodedPath forKey:@"path"];
    }
    
    NSString *method = @"create";
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            weak_clientRequest.internalRequest = [strongSelf _fileRequestWithMethod:method
                                                                      urlParameters:nil
                                                                     bodyParameters:bodyParameters
                                                                    completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _fileRequestWithMethod:method
                                                                             urlParameters:nil
                                                                            bodyParameters:bodyParameters
                                                                           completionBlock:^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

#pragma mark - File PreCreate Request

/**
 @param filePath The absolute path of the files used after upload requires urlencode.
 @param size There are two situations: when uploading a file, it means the size of the file, unit B; when uploading the directory, it means the size of the directory. The default size of the directory is 0.
 @param isDir Is it a directory, 0 files, 1 directory
 @param blockList The json string of each MD5 array of the file. The meaning of block_list is as follows. If the uploaded file is less than 4MB, its md5 value (32-bit lowercase) is the unique element of the block_list string array; if the uploaded file is larger than 4MB, the uploaded file needs to be segmented locally according to the size of 4MB. , the sharding less than 4MB automatically becomes the last shard, and the string array of md5 values (32-bit lowercase) of all shards is block_list.  ["98d02a0f54781a93e354b1fc85caf488", "ca5273571daefb8ea01a42bfa5d02220"]
 @param renamingPolicy File naming policy. 1 indicates that when the path conflicts, rename it. 2 means that when the path conflicts and block_list is different, it is renamed. 3 Override the file with the same name when there is a file in the cloud.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_filePreCreateRequestWithPath:(NSString *)filePath
                                                                                     size:(long long int)size
                                                                                    isDir:(BOOL)isDir
                                                                                blockList:(nullable NSArray<NSString *> *)blockList
                                                                           renamingPolicy:(NSUInteger)renamingPolicy
                                                                          completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(filePath);
    if (filePath == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    NSMutableDictionary *bodyParameters = [NSMutableDictionary new];
    
    [bodyParameters setObject:@(renamingPolicy) forKey:@"rtype"];
    
    //Fixed value 1
    [bodyParameters setObject:@(1) forKey:@"autoinit"];
    
    if (blockList) {
        NSMutableArray *blockListFixed = [NSMutableArray new];
        for (NSString *item in blockList) {
            [blockListFixed addObject:[NSString stringWithFormat:@"\"%@\"",item]];
        }
        NSString *blockListString = [NSString stringWithFormat:@"[%@]",[blockListFixed componentsJoinedByString:@","]];
        [bodyParameters setObject:blockListString forKey:@"block_list"];
    }
    
    [bodyParameters setObject:@(isDir) forKey:@"isdir"];
    
    [bodyParameters setObject:@(size) forKey:@"size"];
    
    NSString *encodedPathParameter = [PanBaiduNetdiskNetworkClient URLEncodedParameters:@{@"path":filePath}];
    NSString *encodedPath = [encodedPathParameter componentsSeparatedByString:@"="].lastObject;
    NSParameterAssert(encodedPath);
    if (encodedPath) {
        [bodyParameters setObject:encodedPath forKey:@"path"];
    }
    
    NSString *method = @"precreate";
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
        
        if (completion){
            completion(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            weak_clientRequest.internalRequest = [strongSelf _fileRequestWithMethod:method
                                                                      urlParameters:nil
                                                                     bodyParameters:bodyParameters
                                                                    completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)[self _fileRequestWithMethod:method
                                                                             urlParameters:nil
                                                                            bodyParameters:bodyParameters
                                                                           completionBlock:^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [strongSelf updateAccessTokenWithCompletionBlock:^{
                retryBlock();
            }];
        }
        else {
            resultCompletion(dictionary,error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

#pragma mark - File Request

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)_fileRequestWithMethod:(NSString *)method
                                                                     urlParameters:(NSDictionary<NSString *,NSString *> *)urlParameters
                                                                    bodyParameters:(NSDictionary<NSString *,NSString *> *)bodyParameters
                                                                   completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(method);
    NSParameterAssert(bodyParameters);
    if (method == nil || bodyParameters == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createCachedCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest)
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processResponse:nil
                                                 withData:nil
                                                    error:error
                                               completion:completion];
            return;
        }
        
        NSMutableDictionary *urlQueryParameters = [@{@"method":method} mutableCopy];
        if (urlParameters) {
            [urlQueryParameters addEntriesFromDictionary:urlParameters];
        }
        
        NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:urlQueryParameters inURL:kPanBaiduNetdiskFileURL];
        NSMutableURLRequest *request = [strongSelf POSTRequestWithURL:requestURL
                                                          contentType:kPanBaiduNetdiskContentTypeApplicationXWWWFormURLEncoded
                                                          accessToken:accessToken];
        
        NSData *body = [PanBaiduNetdiskNetworkClient createBodyWithURLEncodedParameters:bodyParameters];
        [request setHTTPBody:body];
        [request addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
        [PanBaiduNetdiskNetworkClient printRequest:request];
        
        NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            [strongSelf removeCancellableRequestFromCache:weak_clientRequest];
            
            [PanBaiduNetdiskNetworkClient processResponse:response
                                                 withData:data
                                                    error:error
                                               completion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                if (completion) {
                    completion(dictionary,error);
                }
            }];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)task;
        [task resume];
    }];
    return clientRequest;
}

#pragma mark - Network

- (NSMutableURLRequest *_Nullable)GETRequestWithURL:(NSURL *)requestURL
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient GETRequestWithURL:requestURL accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient DELETERequestWithURL:requestURL accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient POSTRequestWithURL:requestURL contentType:contentType accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient PUTRequestWithURL:requestURL contentType:nil accessToken:accessToken];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    return [self.networkClient dataTaskWithRequest:request completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request{
    return [self.networkClient dataTaskWithRequest:request];
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request{
    return [self.networkClient downloadTaskWithRequest:request];
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
{
    return [self.networkClient uploadTaskWithRequest:request fromFile:fileURL];
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    return [self.networkClient uploadTaskWithRequest:request fromData:bodyData completionHandler:completionHandler];
}

#pragma mark - Requests Cache

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cachedCancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier{
    return [self.networkClient.requestsCache cachedCancellableRequestWithURLTaskIdentifier:URLTaskIdentifier];
}

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCachedCancellableRequestsWithURLTasks{
    return [self.networkClient.requestsCache allCachedCancellableRequestsWithURLTasks];
}

- (PanBaiduNetdiskAPIClientRequest *)createCachedCancellableRequest{
    return [self.networkClient.requestsCache createCachedCancellableRequest];
}

- (void)addCancellableRequestToCache:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.networkClient.requestsCache addCancellableRequestToCache:request];
}

- (void)removeCancellableRequestFromCache:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.networkClient.requestsCache removeCancellableRequestFromCache:request];
}

- (void)cancelAndRemoveAllCachedRequests{
    [self.networkClient.requestsCache cancelAndRemoveAllCachedRequests];
}

#pragma mark - Internal

+ (void)dispatchAfterRetryTimeoutBlock:(dispatch_block_t)block{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(kBNDAPIClientRequestRetryTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   ^{
        if (block){
            block();
        }
    });
}

//https://stackoverflow.com/questions/28381183/how-to-calculate-the-hash-of-nsdata-in-ios-efficiently

+ (NSString *)MD5ForSmallData:(NSData *)data
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5([data bytes], (CC_LONG)data.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+ (NSString *)extensionToMIMEType:(NSString *)extension{
    NSString *mimeType = nil;
    
    CFStringRef fileExtension = (__bridge  CFStringRef)extension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (type != NULL){
        CFRelease(type);
    }
    
    if(mimeType==nil){
        mimeType = @"application/octet-stream";
    }
    
    return mimeType;
}

@end

