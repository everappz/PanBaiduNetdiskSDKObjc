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

/**
 @param filePath The absolute path of the files used after upload requires urlencode.
 @param size There are two situations: when uploading a file, it means the size of the file, unit B; when uploading the directory, it means the size of the directory. The default size of the directory is 0.
 @param isDir Is it a directory, 0 files, 1 directory
 @param blockList The json string of each MD5 array of the file. The meaning of block_list is as follows. If the uploaded file is less than 4MB, its md5 value (32-bit lowercase) is the unique element of the block_list string array; if the uploaded file is larger than 4MB, the uploaded file needs to be segmented locally according to the size of 4MB. , the sharding less than 4MB automatically becomes the last shard, and the string array of md5 values (32-bit lowercase) of all shards is block_list.  ["98d02a0f54781a93e354b1fc85caf488", "ca5273571daefb8ea01a42bfa5d02220"]
 @param renamingPolicy File naming policy. 1 indicates that when the path conflicts, rename it. 2 means that when the path conflicts and block_list is different, it is renamed. 3 Override the file with the same name when there is a file in the cloud.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest>)filePreCreateRequestWithPath:(NSString *)filePath
                                                                          size:(long long int)size
                                                                         isDir:(BOOL)isDir
                                                                    blockList:(nullable NSArray<NSString *> *)blockList
                                                                         renamingPolicy:(NSUInteger)renamingPolicy
                                                               completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;


/**
 @param filePath The absolute path of the files used after upload requires urlencode, which needs to be consistent with the path in the pre-upload interface.
 @param size The size of the file or directory must be consistent with the real size of the file, and it needs to be consistent with the size in the pre-upload precreate interface.
 @param isDir Whether the directory, 0 file, 1 directory needs to be consistent with isdir in the pre-upload precreate interface.
 @param blockList The json string of the shard md5 array of files It needs to be consistent with the block_list in the precreate interface, and the md5 returned by the shard upload superfile2 interface should be arranged in order to form the json string of the md5 array.  ["98d02a0f54781a93e354b1fc85caf488", "ca5273571daefb8ea01a42bfa5d02220"]
 @param uploadId Uploadid sent under the precreate interface
 @param renamingPolicy File naming policy, default 0 0 is not renamed, return conflict 1 Rename as long as the path conflicts 2 Rename the path conflict and block_list is different. 3 For coverage, it needs to be consistent with the rtype in the pre-upload precreate interface.
 @param isRevision Do you need multi-version support? 1 is supported, 0 is not supported, and the default is 0 (with this parameter, the renaming policy will be ignored)
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest>)fileCreateRequestWithPath:(NSString *)filePath
                                                                          size:(long long int)size
                                                                         isDir:(BOOL)isDir
                                                                    blockList:(nullable NSArray<NSString *> *)blockList
                                                                   uploadId:(nullable NSString *)uploadId
                                                             renamingPolicy:(NSUInteger)renamingPolicy
                                                                      isRevision:(BOOL)isRevision
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
/*
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)deleteFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                           completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)createFolderForDeviceWithURL:(NSURL *)proxyURL
                                                                    parentID:(NSString *)parentID
                                                                  folderName:(NSString *)folderName
                                                             completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)createFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  parentID:(NSString *)parentID
                                                                  fileName:(NSString *)fileName
                                                              fileMIMEType:(NSString *)fileMIMEType
                                                           completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)renameFileForDeviceWithURL:(NSURL *)proxyURL
                                                                    fileID:(NSString *)fileID
                                                               newFileName:(NSString *)newFileName
                                                           completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)moveFileForDeviceWithURL:(NSURL *)proxyURL
                                                                  fileID:(NSString *)fileID
                                                             newParentID:(NSString *)newParentID
                                                         completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                        fileID:(NSString *)fileID
                                                                    parameters:(NSDictionary *_Nullable)additionalHeaders
                                                           didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                                       didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                               completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)downloadFileContentForDeviceWithURL:(NSURL *)proxyURL
                                                                             fileID:(NSString *)fileID
                                                                      progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                    completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)downloadCompletionBlock;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getDirectURLForDeviceWithURL:(NSURL *)proxyURL
                                                                      fileID:(NSString *)fileID
                                                             completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)completion;

- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)uploadFileContentSeparatelyForDeviceWithURL:(NSURL *)proxyURL
                                                                                     fileID:(NSString *)fileID
                                                                            localContentURL:(NSURL *)localContentURL
                                                                              progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                            completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completionBlock;
*/
@end

NS_ASSUME_NONNULL_END
