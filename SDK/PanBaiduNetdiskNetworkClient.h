//
//  MCHNetwork.h
//  PanBaiduNetdiskSDKObjc
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

@property (nonatomic, strong, readonly) NSURLSession *session;

@property (nonatomic, strong, readonly) PanBaiduNetdiskRequestsCache *requestsCache;

- (NSMutableURLRequest *_Nullable)GETRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *_Nullable)contentType
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           contentType:(NSString *_Nullable)contentType
                                           accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken;

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *_Nullable)contentType
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

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

+ (void)processResponse:(NSURLResponse * _Nullable)response
               withData:(NSData * _Nullable)data
                  error:(NSError * _Nullable)error
             completion:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion;

+ (NSError * _Nullable)processResponse:(NSURLResponse * _Nullable)response
                             withError:(NSError * _Nullable)error
                            completion:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion;

+ (NSURL * _Nullable)processResponseWithURL:(NSURL * _Nullable)url
                                      error:(NSError * _Nullable)error
                                 completion:(PanBaiduNetdiskAPIClientURLBlock _Nullable)completion;

+ (NSURL *)URLByReplacingQueryParameters:(NSDictionary<NSString *,NSString *> *)queryParameters
                                   inURL:(NSURL *)originalURL;

+ (NSString *)URLEncodedParameters:(NSDictionary<NSString *,NSString *> *)params;

+ (NSString *)URLEncodedPath:(NSString *)string;

+ (NSDictionary *_Nullable)queryDictionaryFromURL:(NSURL *)URL;

+ (NSData *)createJSONBodyWithParameters:(NSDictionary<NSString *,NSString *> *)parameters;

+ (NSData *)createMultipartRelatedBodyWithBoundary:(NSString *)boundary
                                        parameters:(NSDictionary<NSString *,NSString *> *)parameters;

+ (NSData *)createMultipartFormDataBodyWithBoundary:(NSString *)boundary
                                      parameterName:(NSString *)parameterName
                                           fileName:(NSString *)fileName
                                           fileData:(NSData *)fileData
                                           mimeType:(NSString *)mimeType;

+ (NSData *)createBodyWithURLEncodedParameters:(NSDictionary<NSString *,NSString *> *)parameters;

+ (NSString *)createMultipartFormBoundary;

+ (void)printRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
