//
//  MCHNetwork.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduNetdiskRequestsCache;
@class PanBaiduNetdiskAccessToken;

@interface PanBaiduNetdiskNetworkClient : NSObject

- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration;

@property (nonatomic,strong,readonly)NSURLSession *session;

@property (nonatomic,strong,readonly)PanBaiduNetdiskRequestsCache *requestsCache;

- (NSMutableURLRequest *_Nullable)GETRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *_Nullable)contentType
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           contentType:(NSString *)contentType
                                           accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *)contentType
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSMutableURLRequest *_Nullable)requestWithURL:(NSURL *)requestURL
                                          method:(NSString *)method
                                     contentType:(NSString *_Nullable)contentType
                                     accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request;

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request;

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL;

+ (void)processDictionaryCompletion:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock)completion
                           withData:(NSData * _Nullable)data
                           response:(NSURLResponse * _Nullable)response
                              error:(NSError * _Nullable)error;

+ (NSError * _Nullable)processErrorCompletion:(PanBaiduNetdiskAPIClientErrorCompletionBlock)completion
                                     response:(NSURLResponse * _Nullable)response
                                        error:(NSError * _Nullable)error;

+ (NSURL * _Nullable)processURLCompletion:(PanBaiduNetdiskAPIClientURLCompletionBlock)completion
                                      url:(NSURL * _Nullable)url
                                    error:(NSError * _Nullable)error;

+ (NSData *)createMultipartRelatedBodyWithBoundary:(NSString *)boundary
                                        parameters:(NSDictionary<NSString *,NSString *> *)parameters;

+ (NSURL *)URLByReplacingQueryParameters:(NSDictionary<NSString *,NSString *> *)queryParameters
                                   inURL:(NSURL *)originalURL;

+ (NSDictionary *_Nullable)queryDictionaryFromURL:(NSURL *)URL;

+ (NSData *)createJSONBodyWithParameters:(NSDictionary<NSString *,NSString *> *)parameters;

+ (NSString *)createMultipartFormBoundary;

+ (void)printRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
