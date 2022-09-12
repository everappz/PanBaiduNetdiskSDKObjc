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

- (void)getAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientAccessTokenCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientVoidCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFilesListAtPath:(NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientArrayCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getInfoForFileWithID:(NSString *)fileID
                                                                           dlink:(BOOL)dlink
                                                                           thumb:(BOOL)thumb
                                                                           extra:(BOOL)extra
                                                                       needmedia:(BOOL)needmedia
                                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)deleteFileAtPath:(NSString *)filePath
                                                   completionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)renameFileAtPath:(NSString *)filePath
                                                           name:(NSString *)name
                                                   completionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)moveFileAtPath:(NSString *)filePath
                                                           toPath:(NSString *)toPath
                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest>)copyFileAtPath:(NSString *)filePath
                                                           toPath:(NSString *)toPath
                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock _Nullable)completion;

/*
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                           completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)createFolderForDeviceWithURL:(NSURL *)proxyURL
                                                                    parentID:(NSString *)parentID
                                                                  folderName:(NSString *)folderName
                                                             completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)createFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  parentID:(NSString *)parentID
                                                                  fileName:(NSString *)fileName
                                                              fileMIMEType:(NSString *)fileMIMEType
                                                           completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)renameFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                               newFileName:(NSString *)newFileName
                                                           completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)moveFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  fileID:(NSString *)fileID
                                                             newParentID:(NSString *)newParentID
                                                         completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                        fileID:(NSString *)fileID
                                                                    parameters:(NSDictionary *_Nullable)additionalHeaders
                                                           didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                                       didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                               completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)downloadFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                             fileID:(NSString *)fileID
                                                                      progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                    completionBlock:(PanBaiduNetdiskAPIClientURLCompletionBlock _Nullable)downloadCompletionBlock;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                                      fileID:(NSString *)fileID
                                                             completionBlock:(PanBaiduNetdiskAPIClientURLCompletionBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
                                                                                     fileID:(NSString *)fileID
                                                                            localContentURL:(NSURL *)localContentURL
                                                                              progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                            completionBlock:(PanBaiduNetdiskAPIClientErrorCompletionBlock _Nullable)completionBlock;
*/
@end

NS_ASSUME_NONNULL_END
