//
//  PanBaiduNetdiskAPIClient.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2023 Everappz. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduAppAuthProvider;
@protocol PanBaiduNetdiskAPIClientCancellableRequest;

/**
 API client for Baidu Pan (Baidu Netdisk) open platform.
 Provides methods for authentication, file management, upload, and download operations.
 Uses the xpan REST API at https://pan.baidu.com/rest/2.0/xpan.
 All network requests support automatic retry on rate limiting (HTTP 429) and token refresh on auth errors.
 */
@interface PanBaiduNetdiskAPIClient : NSObject

#pragma mark - Initialization

/**
 Creates a new client or returns an existing cached client for the given auth data.
 Expects the dictionary to contain PanBaiduNetdiskAccessTokenDataKey (NSData with archived PanBaiduNetdiskAccessToken)
 and PanBaiduNetdiskUserIDKey (NSString) entries.
 @param clientAuthData Dictionary containing access token data and user identifier.
 @return An API client instance, or nil if the auth data is invalid.
 */
+ (nullable PanBaiduNetdiskAPIClient *)createNewOrGetCachedClientWithAuthData:(NSDictionary *)clientAuthData;

/**
 Creates a new client or returns an existing cached client for the given identifier and token.
 @param identifier Unique identifier for the client (typically the user ID).
 @param token Access token for authenticating API requests.
 @param URLSessionConfiguration Optional URL session configuration. Pass nil to use the default configuration.
 @return An API client instance, or nil if identifier or token is nil.
 */
+ (nullable PanBaiduNetdiskAPIClient *)createNewOrGetCachedClientWithIdentifier:(NSString *)identifier
                                                                          token:(PanBaiduNetdiskAccessToken *)token
                                                           sessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration;

/**
 Initializes a new API client with the given session configuration and auth provider.
 @param URLSessionConfiguration Optional URL session configuration. Pass nil to use the default configuration.
 @param authProvider The auth provider responsible for managing OAuth access tokens. May be nil and set later via updateAuthProvider:.
 */
- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration
                                   authProvider:(PanBaiduAppAuthProvider *_Nullable)authProvider;

#pragma mark - Authentication

/**
 Replaces the current auth provider used for obtaining and refreshing access tokens.
 Thread-safe. Can be called at any time to switch accounts or update credentials.
 @param authProvider The new auth provider, or nil to clear.
 */
- (void)updateAuthProvider:(PanBaiduAppAuthProvider * _Nullable)authProvider;

/**
 Retrieves the current valid access token from the auth provider.
 If the token is expired, the auth provider may refresh it before returning.
 @param completion Called with the access token on success, or an error if the auth provider is nil or token retrieval fails.
 */
- (void)getAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientAccessTokenBlock _Nullable)completion;

/**
 Forces a refresh of the access token using the auth provider's refresh token flow.
 @param completion Called when the token update completes (regardless of success or failure).
 @return A cancellable request, or nil if the auth provider is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAPIClientVoidBlock _Nullable)completion;

#pragma mark - User Info

/**
 Fetches the current user's account information.
 API: GET https://pan.baidu.com/rest/2.0/xpan/nas?method=uinfo
 @param completion Called with a dictionary containing user info (baidu_name, netdisk_name, vip_type, etc.) or an error.
 @return A cancellable request.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getUserInfoWithCompletionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

#pragma mark - File Listing

/**
 Lists files and directories at the specified path.
 Automatically paginates through all results (up to 1000 per page).
 API: GET https://pan.baidu.com/rest/2.0/xpan/file?method=list
 @param path The directory path to list. Pass nil or "/" for the root directory.
 @param completion Called with an array of file/directory dictionaries (fs_id, path, server_filename, isdir, size, etc.) or an error.
 @return A cancellable request.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getFilesListAtPath:(nullable NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientArrayBlock _Nullable)completion;

#pragma mark - File Info

/**
 Fetches detailed metadata for a file identified by its fs_id.
 API: GET https://pan.baidu.com/rest/2.0/xpan/multimedia?method=filemetas
 @param fileID The file's fs_id as a string.
 @param dlink YES to include a download link (dlink) in the response. The dlink is valid for 8 hours.
 @param thumb YES to include a thumbnail URL in the response.
 @param extra YES to include extra metadata (e.g., image dimensions).
 @param needmedia YES to include media info (e.g., video resolution, duration).
 @param completion Called with a dictionary containing the file metadata or an error.
 @return A cancellable request.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getInfoForFileWithID:(NSString *)fileID
                                                                           dlink:(BOOL)dlink
                                                                           thumb:(BOOL)thumb
                                                                           extra:(BOOL)extra
                                                                       needmedia:(BOOL)needmedia
                                                                 completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

#pragma mark - File Management

/**
 Moves a file or directory to the recycle bin (trash).
 Files in the recycle bin are retained for 10 days (or 180 days for SVIP users) and can be restored
 by the user through the Baidu Pan web/app interface.
 API: POST https://pan.baidu.com/rest/2.0/xpan/file?method=filemanager&opera=delete
 @param filePath The absolute path of the file or directory to delete.
 @param completion Called with the operation result dictionary or an error.
 @return A cancellable request, or nil if filePath is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)deleteFileAtPath:(NSString *)filePath
                                                             completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

/**
 Renames a file or directory.
 API: POST https://pan.baidu.com/rest/2.0/xpan/file?method=filemanager&opera=rename
 @param filePath The absolute path of the file or directory to rename.
 @param name The new name for the file or directory (filename only, not the full path).
 @param completion Called with the operation result dictionary or an error.
 @return A cancellable request, or nil if filePath or name is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)renameFileAtPath:(NSString *)filePath
                                                                        name:(NSString *)name
                                                             completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

/**
 Moves a file or directory to a new location.
 API: POST https://pan.baidu.com/rest/2.0/xpan/file?method=filemanager&opera=move
 @param filePath The absolute path of the file or directory to move.
 @param toPath The absolute destination path (including the new filename).
 @param completion Called with the operation result dictionary or an error.
 @return A cancellable request, or nil if filePath or toPath is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)moveFileAtPath:(NSString *)filePath
                                                                    toPath:(NSString *)toPath
                                                           completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

/**
 Copies a file or directory to a new location.
 API: POST https://pan.baidu.com/rest/2.0/xpan/file?method=filemanager&opera=copy
 @param filePath The absolute path of the file or directory to copy.
 @param toPath The absolute destination path (including the new filename).
 @param completion Called with the operation result dictionary or an error.
 @return A cancellable request, or nil if filePath or toPath is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)copyFileAtPath:(NSString *)filePath
                                                                    toPath:(NSString *)toPath
                                                           completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

/**
 Creates a new folder at the specified path.
 Uses a renaming policy that automatically renames the folder if one with the same name already exists.
 API: POST https://pan.baidu.com/rest/2.0/xpan/file?method=create
 @param path The absolute path for the new folder.
 @param completion Called with a dictionary containing the created folder's metadata (fs_id, path, etc.) or an error.
 @return A cancellable request.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)createFolderAtPath:(NSString *)path
                                                               completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

#pragma mark - Download

/**
 Downloads file content as a stream of data chunks.
 Internally fetches the file's download link (dlink) first, then streams the content.
 Useful for progressive rendering or writing to disk in chunks.
 @param fileID The file's fs_id as a string.
 @param additionalHeaders Extra HTTP headers to include in the download request (e.g., Range for partial downloads).
 @param didReceiveData Called each time a chunk of data is received.
 @param didReceiveResponse Called when the HTTP response headers are received.
 @param completion Called when the download completes or fails with an error.
 @return A cancellable request, or nil if fileID is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getContentForFileWithID:(NSString *)fileID
                                                                  additionalHeaders:(NSDictionary *)additionalHeaders
                                                                didReceiveDataBlock:(PanBaiduNetdiskAPIClientDidReceiveDataBlock _Nullable)didReceiveData
                                                            didReceiveResponseBlock:(PanBaiduNetdiskAPIClientDidReceiveResponseBlock _Nullable)didReceiveResponse
                                                                    completionBlock:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

/**
 Resolves the direct download URL for a file.
 The returned URL includes the access token and is ready for use in external download managers or media players.
 Internally fetches the file's dlink and appends authentication parameters.
 @param fileID The file's fs_id as a string.
 @param completion Called with the direct download URL or an error.
 @return A cancellable request, or nil if fileID is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)getDirectURLForFileWithID:(NSString *)fileID
                                                                      completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)completion;

/**
 Downloads a file to a temporary location on disk.
 Internally fetches the file's dlink, then downloads to a temporary file using NSURLSessionDownloadTask.
 Reports progress through the progress block.
 @param fileID The file's fs_id as a string.
 @param progressBlock Called periodically with download progress (0.0 to 1.0).
 @param downloadCompletionBlock Called with the local temporary file URL on success, or an error on failure.
                                The caller is responsible for moving the file from the temporary location.
 @return A cancellable request, or nil if fileID is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)downloadContentForFileWithID:(NSString *)fileID
                                                                           progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                         completionBlock:(PanBaiduNetdiskAPIClientURLBlock _Nullable)downloadCompletionBlock;

#pragma mark - Upload

/**
 Uploads a local file to Baidu Pan.
 Uses the chunked upload flow: precreate -> upload chunks (4MB each) -> create file.
 If a file with the same name exists at the remote path, it will be overwritten.
 @param localPath The absolute path to the local file. The file must exist and not be empty.
 @param remotePath The absolute destination path on Baidu Pan (e.g., "/apps/myapp/photo.jpg").
 @param progressBlock Called periodically with overall upload progress (0.0 to 1.0).
 @param completionBlock Called with a dictionary containing the uploaded file's metadata (fs_id, path, size, md5, etc.) or an error.
 @return A cancellable request, or nil if localPath or remotePath is nil.
 */
- (id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)uploadFileFromLocalPath:(NSString *)localPath
                                                                       toRemotePath:(NSString *)remotePath
                                                                      progressBlock:(PanBaiduNetdiskAPIClientProgressBlock _Nullable)progressBlock
                                                                    completionBlock:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completionBlock;

#pragma mark - Request Management

/**
 Cancels all in-flight API requests created by this client.
 */
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
