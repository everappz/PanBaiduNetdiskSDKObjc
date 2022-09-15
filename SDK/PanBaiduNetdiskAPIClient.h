//
//  PanBaiduNetdiskAPIClient.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduAppAuthProvider;
@protocol PanBaiduNetdiskAPIClientCancellableRequest;

@interface PanBaiduNetdiskAPIClient : NSObject

- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
                                   authProvider:(PanBaiduAppAuthProvider *_Nullable)authProvider;

- (void)updateAuthProvider:(PanBaiduAppAuthProvider * _Nullable)authProvider;

- (void)getAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientAccessTokenBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientVoidBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFilesListAtPath:(nullable NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientArrayBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getInfoForFileWithID:(NSString *)fileID
                                                                           dlink:(BOOL)dlink
                                                                           thumb:(BOOL)thumb
                                                                           extra:(BOOL)extra
                                                                       needmedia:(BOOL)needmedia
                                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)deleteFileAtPath:(NSString *)filePath
                                                   completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)renameFileAtPath:(NSString *)filePath
                                                              name:(NSString *)name
                                                   completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)moveFileAtPath:(NSString *)filePath
                                                          toPath:(NSString *)toPath
                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)copyFileAtPath:(NSString *)filePath
                                                          toPath:(NSString *)toPath
                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)createFolderAtPath:(NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getContentForFileWithID:(NSString *)fileID
                                                        additionalHeaders:(NSDictionary *)additionalHeaders
                                                      didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                                  didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                          completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)getDirectURLForFileWithID:(NSString *)fileID
                                                            completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)downloadContentForFileWithID:(NSString *)fileID
                                                                 progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                               completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)downloadCompletionBlock;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)uploadFileFromLocalPath:(NSString *)localPath
                                                             toRemotePath:(NSString *)remotePath
                                                            progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                          completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completionBlock;

- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
