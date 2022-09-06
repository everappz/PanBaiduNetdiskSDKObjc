//
//  PanBaiduNetdiskAPIClient.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
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

NSTimeInterval const kBNDAPIClientRequestRetryTimeout = 1.5;

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

#pragma mark - Public

- (void)getAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientAccessTokenCompletionBlock _Nullable)completion{
    PanBaiduAppAuthProvider *authProvider = nil;
    [self.authProviderLock lock];
    authProvider = self.authProvider;
    [self.authProviderLock unlock];
    
    NSParameterAssert(authProvider);
    
    if(authProvider){
        [authProvider getAccessTokenWithCompletionBlock:completion];
        return;
    }
    
    if(completion){
        completion(nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeAuthProviderIsNil]);
    }
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientVoidCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduAppAuthProvider *authProvider = nil;
    [self.authProviderLock lock];
        authProvider = self.authProvider;
    [self.authProviderLock unlock];
    
    NSParameterAssert(authProvider);
    if(authProvider){
        NSURLSessionDataTask *task = [authProvider updateAccessTokenWithCompletionBlock:^(NSString * _Nullable accessToken, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            [strongSelf removeCancellableRequest:weak_clientRequest];
            if(completion){
                completion();
            }
        }];
        clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
    }
    else{
        [self removeCancellableRequest:clientRequest];
        if(completion){
            completion();
        }
    }
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientDictionaryCompletionBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _getUserInfoWithCompletionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [weakSelf updateAccessTokenWithCompletionBlock:^{
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error)
     {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processDictionaryCompletion:completion
                                                 withData:nil
                                                 response:nil
                                                    error:error];
        }
        else{
            NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:@{@"method":@"uinfo"} inURL:kPanBaiduNetdiskNasURL];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
            [PanBaiduNetdiskNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                
                PanBaiduNetdiskAPIClientDictionaryCompletionBlock resultCompletion =
                ^(NSDictionary * _Nullable resultDictionary, NSError * _Nullable resultError) {
                    if (completion) {
                        completion (resultDictionary, resultError);
                    }
                };
                [PanBaiduNetdiskNetworkClient processDictionaryCompletion:resultCompletion
                                                     withData:data
                                                     response:response
                                                        error:error];
            }];
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFilesListAtPath:(NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientArrayCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientArrayCompletionBlock resultCompletion = ^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(array,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _getFilesListAtPath:path completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getFilesListAtPath:path
                                                        completionBlock:^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [weakSelf updateAccessTokenWithCompletionBlock:^{
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getFilesListAtPath:(NSString *)path
                                                completionBlock:(PanBaiduNetdiskAPIClientArrayCompletionBlock _Nullable)completion{
    NSMutableArray *resultFiles = [NSMutableArray new];
    return [self _getFilesListAtPath:path
                              offset:0
                             length:100
                               resultFiles:resultFiles
                           completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getFilesListAtPath:(NSString *)path
                                                       offset:(NSInteger)offset
                                                      length:(NSInteger)length
                                                    resultFiles:(NSMutableArray *)resultFiles
                                                completionBlock:(PanBaiduNetdiskAPIClientArrayCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
   
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            if(completion){
                completion(nil,error);
            }
        }
        else{
            NSString *pathModified = path?:@"/";
            NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:@{@"method":@"list",@"start":[NSString stringWithFormat:@"%@",@(offset)],@"limit":[NSString stringWithFormat:@"%@",@(length)],@"dir":pathModified} inURL:kPanBaiduNetdiskFileURL];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
            [PanBaiduNetdiskNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [PanBaiduNetdiskNetworkClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
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
                    else{
                        [strongSelf removeCancellableRequest:weak_clientRequest];
                        if(resultFiles.count==0 || error){
                            if(completion){
                                completion(nil,error);
                            }
                        }
                        else{
                            if(completion){
                                completion(resultFiles,nil);
                            }
                        }
                    }
                } withData:data response:response error:error];
            }];
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    return clientRequest;
}







- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getInfoForFileWithID:(NSString *)fileID
                                                                     completionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientDictionaryCompletionBlock resultCompletion = ^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(dictionary,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _getInfoForFileWithID:fileID
                                                                        completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getInfoForFileWithID:fileID
                                                           completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [weakSelf updateAccessTokenWithCompletionBlock:^{
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
                                                        completionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    NSParameterAssert(fileID);
    if(fileID==nil){
        [PanBaiduNetdiskNetworkClient processDictionaryCompletion:completion
                                                         withData:nil
                                                         response:nil
                                                            error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
        return nil;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    
    [self getAccessTokenWithCompletionBlock:
     ^(PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processDictionaryCompletion:completion
                                                             withData:nil
                                                             response:nil
                                                                error:error];
        }
        else{
            
            NSURL *requestURL = [PanBaiduNetdiskNetworkClient URLByReplacingQueryParameters:@{@"method":@"filemetas",@"fsids":[NSString stringWithFormat:@"[%@]",fileID]} inURL:kPanBaiduNetdiskMultimediaURL];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL accessToken:accessToken];
            
            [PanBaiduNetdiskNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processDictionaryCompletion:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                    NSArray *responseArray = nil;
                    if([dictionary isKindOfClass:[NSDictionary class]] && [dictionary objectForKey:@"list"]){
                        responseArray = [dictionary objectForKey:@"list"];
                    }
                    
                    if(completion){
                        completion(responseArray.lastObject,error);
                    }
                }
                                                                 withData:data
                                                                 response:response
                                                                    error:error];
            }];
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    return clientRequest;
}


/*
- (id<PanBaiduNetdiskAPIClientCancellableRequest>)deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                          fileID:(NSString *)fileID
                                                 completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _deleteFileForDeviceWithURL:proxyURL
                                                                                fileID:fileID
                                                                       completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _deleteFileForDeviceWithURL:proxyURL
                                                                   fileID:fileID
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
            resultCompletion(error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                           fileID:(NSString *)fileID
                                                  completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                        response:nil
                                           error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
        return nil;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    id<PanBaiduNetdiskAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                            response:nil
                                               error:error];
        }
        else{
            NSURL *requestURL = [[proxyURL URLByAppendingPathComponent:kBNDSdkV2Files] URLByAppendingPathComponent:fileID];
            NSMutableURLRequest *request = [strongSelf DELETERequestWithURL:requestURL
                                                                contentType:kPanBaiduNetdiskContentTypeApplicationJSON
                                                                accessToken:accessToken];
            [PanBaiduNetdiskNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                                response:response
                                                   error:error];
            }];
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)createFolderForDeviceWithURL:(NSURL *)proxyURL
                                                          parentID:(NSString *)parentID
                                                        folderName:(NSString *)folderName
                                                   completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    return [self createItemForDeviceWithURL:proxyURL
                                   parentID:parentID
                                   itemName:folderName
                               itemMIMEType:kBNDMIMETypeFolder
                            completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)createFileForDeviceWithURL:(NSURL *)proxyURL
                                                        parentID:(NSString *)parentID
                                                        fileName:(NSString *)fileName
                                                    fileMIMEType:(NSString *)fileMIMEType
                                                 completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    return [self createItemForDeviceWithURL:proxyURL
                                   parentID:parentID
                                   itemName:fileName
                               itemMIMEType:fileMIMEType
                            completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)createItemForDeviceWithURL:(NSURL *)proxyURL
                                                        parentID:(NSString *)parentID
                                                        itemName:(NSString *)itemName
                                                    itemMIMEType:(NSString *)itemMIMEType
                                                 completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _createItemForDeviceWithURL:proxyURL
                                                                              parentID:parentID
                                                                              itemName:itemName
                                                                          itemMIMEType:itemMIMEType
                                                                       completionBlock:resultCompletion];
        }];
    };
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _createItemForDeviceWithURL:proxyURL
                                                                 parentID:parentID
                                                                 itemName:itemName
                                                             itemMIMEType:itemMIMEType
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
            resultCompletion(error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_createItemForDeviceWithURL:(NSURL *)proxyURL
                                                         parentID:(NSString *)parentID
                                                         itemName:(NSString *)itemName
                                                     itemMIMEType:(NSString *)itemMIMEType
                                                  completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(parentID);
    NSParameterAssert(itemName);
    NSParameterAssert(itemMIMEType);
    if(proxyURL==nil || parentID==nil || itemName==nil || itemMIMEType==nil){
        [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                        response:nil
                                           error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
        return nil;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    id<PanBaiduNetdiskAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                            response:nil
                                               error:error];
        }
        else{
            NSURL *requestURL = [proxyURL URLByAppendingPathComponent:kBNDSdkV2Files];
            NSString *boundary = [PanBaiduNetdiskNetworkClient createMultipartFormBoundary];
            NSString *contentType = [NSString stringWithFormat:@"%@;boundary=%@",
                                     kPanBaiduNetdiskContentTypeMultipartRelated,
                                     boundary];
            NSMutableURLRequest *request = [strongSelf POSTRequestWithURL:requestURL
                                                              contentType:contentType
                                                              accessToken:accessToken];
            NSDictionary *parameters = @{@"name":itemName,
                                         @"parentID":parentID};
            if(itemMIMEType.length>0){
                NSMutableDictionary *mparameters = [parameters mutableCopy];
                [mparameters setObject:itemMIMEType forKey:@"mimeType"];
                parameters = mparameters;
            }
            NSData *body = [PanBaiduNetdiskNetworkClient createMultipartRelatedBodyWithBoundary:boundary
                                                                         parameters:parameters];
            [request setHTTPBody:body];
            [request addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
            [PanBaiduNetdiskNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                                response:response
                                                   error:error];
            }];
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)renameFileForDeviceWithURL:(NSURL *)proxyURL
                                                          fileID:(NSString *)fileID
                                                     newFileName:(NSString *)newFileName
                                                 completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    NSDictionary *parameters = @{@"name":newFileName};
    return [self patchFileForDeviceWithURL:proxyURL
                                    fileID:fileID
                                parameters:parameters
                           completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)moveFileForDeviceWithURL:(NSURL *)proxyURL
                                                        fileID:(NSString *)fileID
                                                   newParentID:(NSString *)newParentID
                                               completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    NSDictionary *parameters = @{@"parentID":newParentID};
    return [self patchFileForDeviceWithURL:proxyURL
                                    fileID:fileID
                                parameters:parameters
                           completionBlock:completion];
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)patchFileForDeviceWithURL:(NSURL *)proxyURL
                                                         fileID:(NSString *)fileID
                                                     parameters:(NSDictionary<NSString *,NSString *> *)parameters
                                                completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _patchFileForDeviceWithURL:proxyURL
                                                                               fileID:fileID
                                                                           parameters:parameters
                                                                      completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _patchFileForDeviceWithURL:proxyURL
                                                                  fileID:fileID
                                                              parameters:parameters
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
            resultCompletion(error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_patchFileForDeviceWithURL:(NSURL *)proxyURL
                                                          fileID:(NSString *)fileID
                                                      parameters:(NSDictionary<NSString *,NSString *> *)parameters
                                                 completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    NSParameterAssert(parameters);
    if(proxyURL==nil || fileID==nil || parameters==nil){
        [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                        response:nil
                                           error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
        return nil;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    id<PanBaiduNetdiskAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                            response:nil
                                               error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kBNDSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kBNDPatch];
            NSMutableURLRequest *request = [strongSelf POSTRequestWithURL:requestURL
                                                              contentType:kPanBaiduNetdiskContentTypeApplicationJSON
                                                              accessToken:accessToken];
            NSData *body = [PanBaiduNetdiskNetworkClient createJSONBodyWithParameters:parameters];
            [request setHTTPBody:body];
            [request addValue:[NSString stringWithFormat:@"%@",@(body.length)] forHTTPHeaderField:@"Content-Length"];
            [PanBaiduNetdiskNetworkClient printRequest:request];
            NSURLSessionDataTask *task = [strongSelf dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                                response:response
                                                   error:error];
            }];
            weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
            [task resume];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                              fileID:(NSString *)fileID
                                                          parameters:(NSDictionary *)additionalHeaders
                                                 didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                             didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                     completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _getFileContentForDeviceWithURL:proxyURL
                                                                                    fileID:fileID
                                                                                parameters:additionalHeaders
                                                                       didReceiveDataBlock:didReceiveData
                                                                   didReceiveResponseBlock:didReceiveResponse
                                                                           completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getFileContentForDeviceWithURL:proxyURL
                                                                       fileID:fileID
                                                                   parameters:additionalHeaders
                                                          didReceiveDataBlock:didReceiveData
                                                      didReceiveResponseBlock:didReceiveResponse
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
            completion(error);
        }
    }];
    clientRequest.internalRequest = internalRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                               fileID:(NSString *)fileID
                                                           parameters:(NSDictionary *)additionalHeaders
                                                  didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                              didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                      completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [PanBaiduNetdiskNetworkClient processErrorCompletion:completion
                                        response:nil
                                           error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
        return nil;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    clientRequest.didReceiveDataBlock = didReceiveData;
    clientRequest.didReceiveResponseBlock = didReceiveResponse;
    clientRequest.errorCompletionBlock = completion;
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    id<PanBaiduNetdiskAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processErrorCompletion:completion response:nil error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kBNDSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kBNDContent];
            NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                             contentType:nil
                                                             accessToken:accessToken];
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
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                            fileID:(NSString *)fileID
                                                   completionBlock:(PanBaiduNetdiskAPIClientURLCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientURLCompletionBlock resultCompletion = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (completion){
            completion(location,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _getDirectURLForDeviceWithURL:proxyURL
                                                                                  fileID:fileID
                                                                         completionBlock:resultCompletion];
        }];
    };
    
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _getDirectURLForDeviceWithURL:proxyURL
                                                                     fileID:fileID
                                                            completionBlock:^(NSURL *_Nullable location, NSError * _Nullable error) {
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [weakSelf updateAccessTokenWithCompletionBlock:^{
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                             fileID:(NSString *)fileID
                                                    completionBlock:(PanBaiduNetdiskAPIClientURLCompletionBlock _Nullable)completion{
    PanBaiduNetdiskMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [PanBaiduNetdiskNetworkClient processURLCompletion:completion
                                           url:nil
                                         error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
        return nil;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    id<PanBaiduNetdiskAPIClientCancellableRequest> tokenRequest =
    [self getAccessTokenWithCompletionBlock:
     ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        if(error){
            [strongSelf removeCancellableRequest:weak_clientRequest];
            [PanBaiduNetdiskNetworkClient processURLCompletion:completion
                                               url:nil
                                             error:error];
        }
        else{
            NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kBNDSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kBNDContent];
            NSString *requestURLStringWithAuth = [NSString stringWithFormat:@"%@?access_token=%@",requestURL.absoluteString,accessToken.token];
            NSURL *requestURLWithAuth = [NSURL URLWithString:requestURLStringWithAuth];
            [PanBaiduNetdiskNetworkClient processURLCompletion:completion
                                               url:requestURLWithAuth
                                             error:(requestURLWithAuth==nil)?[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeCannotGetDirectURL]:nil];
        }
    }];
    clientRequest.internalRequest = tokenRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)downloadFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                   fileID:(NSString *)fileID
                                                            progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                          completionBlock:(PanBaiduNetdiskAPIClientURLCompletionBlock _Nullable)downloadCompletionBlock{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientURLCompletionBlock resultCompletion = ^(NSURL *_Nullable location, NSError * _Nullable error) {
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        [strongSelf removeCancellableRequest:weak_clientRequest];
        if (downloadCompletionBlock){
            downloadCompletionBlock(location,error);
        }
    };
    
    void(^retryBlock)(void) = ^{
        [PanBaiduNetdiskAPIClient dispatchAfterRetryTimeoutBlock:^{
            PanBaiduNetdiskCheckIfClientRequestIsCancelledOrNilAndReturn(weak_clientRequest);
            weak_clientRequest.internalRequest = [weakSelf _downloadFileContentForDeviceWithURL:proxyURL
                                                                                         fileID:fileID
                                                                                  progressBlock:progressBlock
                                                                                completionBlock:resultCompletion];
        }];
    };
    id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest =
    (id<PanBaiduNetdiskAPIClientCancellableRequest>)[self _downloadFileContentForDeviceWithURL:proxyURL
                                                                            fileID:fileID
                                                                     progressBlock:progressBlock
                                                                   completionBlock:^(NSURL *_Nullable location, NSError * _Nullable error) {
        if (error.isPanBaiduNetdiskTooManyRequestsError) {
            retryBlock();
        }
        else if (error.isPanBaiduNetdiskAuthError){
            [weakSelf updateAccessTokenWithCompletionBlock:^{
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

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)_downloadFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                             progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                           completionBlock:(PanBaiduNetdiskAPIClientURLCompletionBlock _Nullable)downloadCompletionBlock{
    PanBaiduNetdiskMakeWeakSelf;
    NSParameterAssert(proxyURL);
    NSParameterAssert(fileID);
    if(proxyURL==nil || fileID==nil){
        [PanBaiduNetdiskNetworkClient processURLCompletion:downloadCompletionBlock
                                           url:nil
                                         error:[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]];
        return nil;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    clientRequest.progressBlock = progressBlock;
    clientRequest.downloadCompletionBlock = downloadCompletionBlock;
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    id<PanBaiduNetdiskAPIClientCancellableRequest> infoRequest = [self getFileInfoForDeviceWithURL:proxyURL
                                                                                fileID:fileID
                                                                       completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        if(dictionary){
            PanBaiduNetdiskFile *file = [[PanBaiduNetdiskFile alloc] initWithDictionary:dictionary];
            weak_clientRequest.totalContentSize = file.size;
        }
        PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
        id<PanBaiduNetdiskAPIClientCancellableRequest> tokenRequest =
        [strongSelf getAccessTokenWithCompletionBlock:
         ^(id<MCHEndpointConfiguration> _Nullable endpointConfiguration, PanBaiduNetdiskAccessToken * _Nullable accessToken, NSError * _Nullable error) {
            PanBaiduNetdiskMakeStrongSelfAndReturnIfNil;
            if(error){
                [strongSelf removeCancellableRequest:weak_clientRequest];
                [PanBaiduNetdiskNetworkClient processURLCompletion:downloadCompletionBlock
                                                   url:nil
                                                 error:error];
            }
            else{
                NSURL *requestURL = [[[proxyURL URLByAppendingPathComponent:kBNDSdkV2Files] URLByAppendingPathComponent:fileID] URLByAppendingPathComponent:kBNDContent];
                NSMutableURLRequest *request = [strongSelf GETRequestWithURL:requestURL
                                                                 contentType:nil
                                                                 accessToken:accessToken];
                [PanBaiduNetdiskNetworkClient printRequest:request];
                NSURLSessionDownloadTask *task = [strongSelf downloadTaskWithRequest:request];
                weak_clientRequest.URLTaskIdentifier = task.taskIdentifier;
                weak_clientRequest.internalRequest = (id<PanBaiduNetdiskAPIClientCancellableRequest>)task;
                [task resume];
            }
        }];
        clientRequest.internalRequest = tokenRequest;
    }];
    clientRequest.internalRequest = infoRequest;
    return clientRequest;
}

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
                                                                           fileID:(NSString *)fileID
                                                                  localContentURL:(NSURL *)localContentURL
                                                                    progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                  completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completionBlock{
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskAPIClientRequest *clientRequest = [self createAndAddCancellableRequest];
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    PanBaiduNetdiskAPIClientErrorCompletionBlock resultCompletion = ^(NSError * _Nullable error) {
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
                                                                   completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completionBlock{
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
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken{
    return [self.networkClient GETRequestWithURL:requestURL
                                     contentType:nil
                                     accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken{
    return [self.networkClient DELETERequestWithURL:requestURL
                                        contentType:nil
                                        accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken{
    return [self.networkClient POSTRequestWithURL:requestURL
                                      contentType:contentType
                                      accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken{
    return [self.networkClient PUTRequestWithURL:requestURL
                                     contentType:nil
                                     accessToken:accessToken];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
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

