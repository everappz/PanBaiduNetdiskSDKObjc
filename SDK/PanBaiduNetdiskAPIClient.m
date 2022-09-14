//
//  PanBaiduNetdiskAPIClient.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

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

#define PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest) if (weak_clientRequest == nil || weak_clientRequest.isCancelled){ return; }

NSTimeInterval const kBNDAPIClientRequestRetryTimeout = 2.0;

@interface PanBaiduNetdiskAPIClient()

@property (nonatomic,strong)PanBaiduNetdiskNetworkClient *networkClient;
@property (nonatomic,strong,nullable)PanBaiduAppAuthProvider *authProvider;
@property (nonatomic,strong,nullable)NSRecursiveLock *authProviderLock;

@end


@implementation PanBaiduNetdiskAPIClient


- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
                                   authProvider:(PanBaiduAppAuthProvider *_Nullable)authProvider
{
    self = [super init];
    if(self){
        self.authProvider = authProvider;
        self.authProviderLock = [NSRecursiveLock new];
        self.networkClient = [[PanBaiduNetdiskNetworkClient alloc] initWithURLSessionConfiguration:URLSessionConfiguration];
    }
    return self;
}

- (void)updateAuthProvider:(PanBaiduAppAuthProvider *_Nullable)authProvider{
    [self.authProviderLock lock];
    self.authProvider = authProvider;
    [self.authProviderLock unlock];
}

#pragma mark - Access Token

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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientVoidBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
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
            [strongSelf removeCancellableRequest:weak_clientRequest];
            
            if (completion) {
                completion();
            }
        }];
        clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
        return clientRequest;
    }
    
    [self removeCancellableRequest:clientRequest];
    if (completion) {
        completion();
    }
    return nil;
}

#pragma mark - User Info

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error)
     {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequest:weak_clientRequest];
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
            [strongSelf removeCancellableRequest:weak_clientRequest];
            
            PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion =
            ^(NSDictionary * _Nullable resultDictionary, NSError * _Nullable resultError) {
                if (completion) {
                    completion (resultDictionary, resultError);
                }
            };
            [PanBaiduNetdiskNetworkClient processResponse:response
                                                 withData:data
                                                    error:error
                                               completion:resultCompletion];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
        [task resume];
    }];
    
    return clientRequest;
}

#pragma mark - Files List

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFilesListAtPath:(nullable NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientArrayBlock _Nullable)completion
{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientArrayBlock resultCompletion = ^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getFilesListAtPath:path
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getFilesListAtPath:(nullable NSString *)path
                                                      completionBlock:(PanBaiduNetdiskAPIClientArrayBlock _Nullable)completion
{
    NSMutableArray *resultFiles = [NSMutableArray new];
    
    //The number of queries defaults to 1000, and it is recommended that the maximum number should not exceed 1000.
    return [self _getFilesListAtPath:path offset:0 length:1000 resultFiles:resultFiles completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getFilesListAtPath:(nullable NSString *)path
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if (error) {
            [strongSelf removeCancellableRequest:weak_clientRequest];
            if (completion) {
                completion(nil,error);
            }
            return;
        }
        
        NSString *pathModified = path?:@"/";
        NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:@{@"method":@"list",@"start":[NSString stringWithFormat:@"%@",@(offset)],@"limit":[NSString stringWithFormat:@"%@",@(length)],@"dir":pathModified} inURL:kPanBaiduNetdiskFileURL];
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
                    weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)nextPageRequest;
                }
                else {
                    [strongSelf removeCancellableRequest:weak_clientRequest];
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
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getInfoForFileWithID:fileID
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getInfoForFileWithID:(NSString *)fileID
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequest:weak_clientRequest];
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
        
        NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            [strongSelf removeCancellableRequest:weak_clientRequest];
            
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
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
        [task resume];
    }];
    return clientRequest;
}

#pragma mark - File Create Request

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)fileCreateRequestWithPath:(NSString *)filePath
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
    [bodyParameters setObject:encodedPath forKey:@"path"];
    
    NSString *method = @"create";
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _fileRequestWithMethod:method
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)filePreCreateRequestWithPath:(NSString *)filePath
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
    [bodyParameters setObject:encodedPath forKey:@"path"];
    
    NSString *method = @"precreate";
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _fileRequestWithMethod:method
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_fileRequestWithMethod:(NSString *)method
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest)
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequest:weak_clientRequest];
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
            [strongSelf removeCancellableRequest:weak_clientRequest];
            
            [PanBaiduNetdiskNetworkClient processResponse:response
                                                 withData:data
                                                    error:error
                                               completion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                if (completion) {
                    completion(dictionary,error);
                }
            }];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
        [task resume];
    }];
    return clientRequest;
}

#pragma mark - File Manager Request

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)deleteFileAtPath:(NSString *)filePath
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)renameFileAtPath:(NSString *)filePath
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)moveFileAtPath:(NSString *)filePath
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)copyFileAtPath:(NSString *)filePath
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_defaultFileManagerRequestWithMethod:(NSString *)method
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_fileManagerRequestWithMethod:(NSString *)method
                                                                 bodyParameters:(NSDictionary<NSString *,NSString *> *)bodyParameters
                                                                completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSParameterAssert(method);
    if (method == nil) {
        if (completion) {
            completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
        }
        return nil;
    }
    
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientDictionaryBlock resultCompletion = ^(NSDictionary *_Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
        if (completion){
            completion(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            
            weak_clientRequest.internalRequest = [strongSelf _fileRequestWithMethod:@"filemanager"
                                                                      urlParameters:@{@"opera":method}
                                                                     bodyParameters:bodyParameters
                                                                    completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _fileRequestWithMethod:@"filemanager"
                                                                   urlParameters:@{@"opera":method}
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getContentForFileWithID:(NSString *)fileID
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientErrorBlock resultCompletion = ^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getContentForFileWithID:fileID
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
            completion(error);
        }
    }];
    
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getContentForFileWithID:(NSString *)fileID
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
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    clientRequest.didReceiveDataBlock = didReceiveData;
    clientRequest.didReceiveResponseBlock = didReceiveResponse;
    clientRequest.errorCompletionBlock = completion;
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskMakeWeakSelf;
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequest:weak_clientRequest];
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
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processResponse:nil
                                                    withError:error
                                                   completion:completion];
            }
            else if (downloadURL == nil) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
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
                weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
                [PanBaiduNetdiskNetworkClient printRequest:request];
                [task resume];
            }
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)fileInfoRequest;
    }];
    
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getDirectURLForFileWithID:(NSString *)fileID
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientURLBlock resultCompletion = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getDirectURLForFileWithID:fileID
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getDirectURLForFileWithID:(NSString *)fileID
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequest:weak_clientRequest];
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
            
            [strongSelf removeCancellableRequest:weak_clientRequest];
            
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
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)fileInfoRequest;
    }];
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)downloadContentForFileWithID:(NSString *)fileID
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
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    PanBaiduNetdiskAPIClientURLBlock resultCompletion = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
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
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _downloadContentForFileWithID:fileID
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_downloadContentForFileWithID:(NSString *)fileID
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
    
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskMakeWeakSelf;
    clientRequest.progressBlock = progressBlock;
    
    clientRequest.downloadCompletionBlock = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        
        if (downloadCompletionBlock) {
            downloadCompletionBlock(location,error);
        }
    };
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        
        if (error) {
            [strongSelf removeCancellableRequest:weak_clientRequest];
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
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processResponseWithURL:nil
                                                               error:error
                                                          completion:downloadCompletionBlock];
                return;
            }
            
            if (downloadURL == nil) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
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
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
            [task resume];
        }];
        
        weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)fileInfoRequest;
    }];
    
    return clientRequest;
}


/*
 
 - (id<PanBaiduNetdiskAPIClientCancellableRequest>)uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
 fileID:(NSString *)fileID
 localContentURL:(NSURL *)localContentURL
 progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
 completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completionBlock{
 PanBaiduNetdiskMakeWeakSelf;
 PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
 PanBaiduNetdiskMakeWeakReference(clientRequest);
 PanBaiduNetdiskAPIClientErrorBlock resultCompletion = ^(NSError * _Nullable error) {
 PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
 [strongSelf removeCancellableRequest:weak_clientRequest];
 if (completionBlock){
 completionBlock(error);
 }
 };
 
 void(^retryBlock)(void) = ^{
 [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
 PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
 weak_clientRequest.internalRequest = [weakSelf _uploadFileContentSeparatelyForDeviceWithURL:proxyURL
 fileID:fileID
 localContentURL:localContentURL
 progressBlock:progressBlock
 completionBlock:resultCompletion];
 }];
 };
 
 id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
 (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _uploadFileContentSeparatelyForDeviceWithURL:proxyURL
 fileID:fileID
 localContentURL:localContentURL
 progressBlock:progressBlock
 completionBlock:^(NSError * _Nullable error) {
 if (error.isPanBaiduNetdiskTooManyRequestsError) {
 retryBlock();
 }
 else if (error.isPanBaiduNetdiskAuthError){
 [weakSelf updateAccessTokenWithCompletionBlock:^{
 retryBlock();
 }];
 }
 else {
 completionBlock(error);
 }
 }];
 clientRequest.internalRequest = internalRequest;
 return clientRequest;
 }
 
 - (id<PanBaiduNetdiskAPIClientCancellableRequest>)_uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
 fileID:(NSString *)fileID
 localContentURL:(NSURL *)localContentURL
 progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
 completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completionBlock{
 PanBaiduNetdiskMakeWeakSelf;
 NSParameterAssert(proxyURL);
 NSParameterAssert(fileID);
 NSParameterAssert(localContentURL);
 if(proxyURL==nil || fileID==nil || localContentURL==nil){
 [PanBaiduNetdiskNetworkClient processErrorCompletion:completionBlock
 response:nil
 error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
 return nil;
 }
 if ([[NSFileManager defaultManager] fileExistsAtPath:localContentURL.path] == NO) {
 [PanBaiduNetdiskNetworkClient processErrorCompletion:completionBlock
 response:nil
 error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeLocalFileNotFound]];
 return nil;
 }
 unsigned long long contentSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:localContentURL.path error:nil] fileSize];
 if(contentSize==0 || contentSize==-1){
 [PanBaiduNetdiskNetworkClient processErrorCompletion:completionBlock
 response:nil
 error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeLocalFileEmpty]];
 return nil;
 }
 
 PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
 clientRequest.progressBlock = progressBlock;
 clientRequest.errorCompletionBlock = completionBlock;
 clientRequest.totalContentSize = @(contentSize);
 PanBaiduNetdiskMakeWeakReference(clientRequest);
 
 id<PanBaiduNetdiskAPIClientCancellableRequest> tokenRequest =
 [self getAccessTokenWithCompletionBlock:
 ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
 PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
 if(error){
 [strongSelf removeCancellableRequest:weak_clientRequest];
 [PanBaiduNetdiskNetworkClient processErrorCompletion:completionBlock
 response:nil
 error:error];
 }
 else{
 NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kBNDSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kBNDContent];
 NSMutableURLRequest *request = [strongSelf PUTRequestWithURL:requestURL
 contentType:kPanBaiduNetdiskContentTypeApplicationXWWWFormURLEncoded
 accessToken:accessToken];
 [PanBaiduNetdiskNetworkClient printRequest:request];
 NSURLSessionUploadTask *task = [strongSelf uploadTaskWithRequest:request
 fromFile:localContentURL];
 weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
 weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
 [task resume];
 }
 }];
 
 clientRequest.internalRequest = tokenRequest;
 return clientRequest;
 }
 */

#pragma mark - Network

- (NSMutableURLRequest *_Nullable)GETRequestWithURL:(NSURL *)requestURL
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient GETRequestWithURL:requestURL
                                     contentType:nil
                                     accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient DELETERequestWithURL:requestURL
                                        contentType:nil
                                        accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient POSTRequestWithURL:requestURL
                                      contentType:contentType
                                      accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self.networkClient PUTRequestWithURL:requestURL
                                     contentType:nil
                                     accessToken:accessToken];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    return [self.networkClient dataTaskWithRequest:request
                                 completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request{
    return [self.networkClient dataTaskWithRequest:request];
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request{
    return [self.networkClient downloadTaskWithRequest:request];
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL{
    return [self.networkClient uploadTaskWithRequest:request
                                            fromFile:fileURL];
}

#pragma mark - Requests Cache

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier{
    return [self.networkClient.requestsCache cancellableRequestWithURLTaskIdentifier:URLTaskIdentifier];
}

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks{
    return [self.networkClient.requestsCache allCancellableRequestsWithURLTasks];
}

- (PanBaiduNetdiskAPIClientRequest *)createAndAddCancellableRequest{
    return [self.networkClient.requestsCache createAndAddCancellableRequest];
}

- (void)addCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.networkClient.requestsCache addCancellableRequest:request];
}

- (void)removeCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.networkClient.requestsCache removeCancellableRequest:request];
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

@end

