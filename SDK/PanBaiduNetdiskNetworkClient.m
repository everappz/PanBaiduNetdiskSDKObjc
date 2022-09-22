//
//  MCHNetwork.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "PanBaiduNetdiskNetworkClient.h"
#import "NSError+PanBaiduNetdisk.h"
#import "PanBaiduNetdiskAPIClientRequest.h"
#import "PanBaiduNetdiskRequestsCache.h"
#import "PanBaiduNetdiskAccessToken.h"


@interface PanBaiduNetdiskNetworkClient()
<
NSURLSessionTaskDelegate,
NSURLSessionDelegate,
NSURLSessionDataDelegate,
NSURLSessionDownloadDelegate
>

@property (nonatomic,strong)NSURLSession *session;

@property (nonatomic,strong)PanBaiduNetdiskRequestsCache *requestsCache;

@end



@implementation PanBaiduNetdiskNetworkClient


- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *resultConfiguration = URLSessionConfiguration;
        if (resultConfiguration == nil) {
            resultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            resultConfiguration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
            resultConfiguration.allowsCellularAccess = YES;
            resultConfiguration.timeoutIntervalForRequest = 30;
            resultConfiguration.HTTPMaximumConnectionsPerHost = 1;
        }
        
        NSOperationQueue *callbackQueue = [[NSOperationQueue alloc] init];
        callbackQueue.maxConcurrentOperationCount = 1;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:resultConfiguration
                                                              delegate:self
                                                         delegateQueue:callbackQueue];
        self.session = session;
        
        self.requestsCache = [PanBaiduNetdiskRequestsCache new];
    }
    return self;
}

- (NSMutableURLRequest *_Nullable)GETRequestWithURL:(NSURL *)requestURL
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self requestWithURL:requestURL
                         method:@"GET"
                    contentType:nil
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self requestWithURL:requestURL
                         method:@"DELETE"
                    contentType:nil
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)POSTRequestWithURL:(NSURL *)requestURL
                                         contentType:(NSString *)contentType
                                         accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self requestWithURL:requestURL
                         method:@"POST"
                    contentType:contentType
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)PUTRequestWithURL:(NSURL *)requestURL
                                        contentType:(NSString *_Nullable)contentType
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self requestWithURL:requestURL
                         method:@"PUT"
                    contentType:contentType
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)requestWithURL:(NSURL *)requestURL
                                          method:(NSString *)method
                                     contentType:(NSString *_Nullable)contentType
                                     accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    NSParameterAssert(requestURL);
    if (requestURL == nil) {
        return nil;
    }
    
    NSParameterAssert(method);
    if (method == nil) {
        return nil;
    }
    
    NSString *token = nil;
    NSURL *requestURLModified = requestURL;
    
    if (accessToken) {
        token = accessToken.accessToken;
        NSParameterAssert(token);
    }
    
    NSString *accessTokenStringFromComponents = [PanBaiduNetdiskNetworkClient accessTokenFromURL:requestURL];
    
    if (accessTokenStringFromComponents == nil && token != nil) {
        NSURLComponents *components = [NSURLComponents componentsWithString:requestURL.absoluteString];
        NSMutableArray *queryItemsUpdated = [components.queryItems mutableCopy];
        NSURLQueryItem *accessTokenItem = [NSURLQueryItem queryItemWithName:@"access_token" value:token];
        [queryItemsUpdated addObject:accessTokenItem];
        components.queryItems = queryItemsUpdated;
        requestURLModified = components.URL;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURLModified];
    [request setHTTPMethod:method];
    
    if (contentType) {
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
    
    [request addValue:@"pan.baidu.com" forHTTPHeaderField:@"User-Agent"];
    
    NSParameterAssert([PanBaiduNetdiskNetworkClient accessTokenFromURL:request.URL] != nil);
    
    return request;
}

- (NSURLSessionDataTask *_Nullable)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if (self.session && request) {
        return [self.session dataTaskWithRequest:request completionHandler:completionHandler];
    }
    if (completionHandler) {
        completionHandler(nil,nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
    }
    return nil;
}

- (NSURLSessionDataTask *_Nullable)dataTaskWithRequest:(NSURLRequest *)request{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if (self.session && request) {
        return [self.session dataTaskWithRequest:request];
    }
    return nil;
}

- (NSURLSessionDownloadTask *_Nullable)downloadTaskWithRequest:(NSURLRequest *)request{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if (self.session && request) {
        return [self.session downloadTaskWithRequest:request];
    }
    return nil;
}

- (NSURLSessionUploadTask *_Nullable)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if (self.session && request) {
        return [self.session uploadTaskWithRequest:request fromFile:fileURL];
    }
    return nil;
}

- (NSURLSessionUploadTask *_Nullable)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if (self.session && request) {
        return [self.session uploadTaskWithRequest:request fromData:bodyData completionHandler:completionHandler];
    }
    return nil;
}

#pragma mark - NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    if (completionHandler) {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(nullable NSError *)error
{
    NSArray *tasks = [self allCachedCancellableRequestsWithURLTasks];
    for (PanBaiduNetdiskAPIClientRequest *obj in tasks) {
        if (obj.errorCompletionBlock) {
            obj.errorCompletionBlock(error);
        }
        [self removeCancellableRequestFromCache:obj];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    PanBaiduNetdiskAPIClientRequest *request = [self cachedCancellableRequestWithURLTaskIdentifier:task.taskIdentifier];
    int64_t totalSize = totalBytesExpectedToSend>0?totalBytesExpectedToSend:[request.totalContentSize longLongValue];
    if (request.progressBlock && totalSize > 0) {
        request.progressBlock((float)totalBytesSent/(float)totalSize);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    PanBaiduNetdiskAPIClientRequest *request = [self cachedCancellableRequestWithURLTaskIdentifier:task.taskIdentifier];
    if (request.errorCompletionBlock) {
        request.errorCompletionBlock(error);
    }
    if (request.downloadCompletionBlock) {
        request.downloadCompletionBlock(nil,error);
    }
    [self removeCancellableRequestFromCache:request];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    PanBaiduNetdiskAPIClientRequest *request = [self cachedCancellableRequestWithURLTaskIdentifier:dataTask.taskIdentifier];
    if (request.didReceiveResponseBlock) {
        request.didReceiveResponseBlock(response);
    }
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    PanBaiduNetdiskAPIClientRequest *request = [self cachedCancellableRequestWithURLTaskIdentifier:dataTask.taskIdentifier];
    if (request.didReceiveDataBlock) {
        request.didReceiveDataBlock(data);
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    PanBaiduNetdiskAPIClientRequest *request = [self cachedCancellableRequestWithURLTaskIdentifier:downloadTask.taskIdentifier];
    if(request.downloadCompletionBlock){
        request.downloadCompletionBlock(location,nil);
    }
    [self removeCancellableRequestFromCache:request];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    PanBaiduNetdiskAPIClientRequest *request = [self cachedCancellableRequestWithURLTaskIdentifier:downloadTask.taskIdentifier];
    int64_t totalSize = totalBytesExpectedToWrite>0?totalBytesExpectedToWrite:[request.totalContentSize longLongValue];
    if(request.progressBlock && totalSize>0){
        request.progressBlock((float)totalBytesWritten/(float)totalSize);
    }
}

#pragma mark - Requests Cache

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cachedCancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier{
    return [self.requestsCache cachedCancellableRequestWithURLTaskIdentifier:URLTaskIdentifier];
}

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCachedCancellableRequestsWithURLTasks{
    return [self.requestsCache allCachedCancellableRequestsWithURLTasks];
}

- (PanBaiduNetdiskAPIClientRequest *)createCachedCancellableRequest{
    return [self.requestsCache createCachedCancellableRequest];
}

- (void)addCancellableRequestToCache:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.requestsCache addCancellableRequestToCache:request];
}

- (void)removeCancellableRequestFromCache:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.requestsCache removeCancellableRequestFromCache:request];
}

#pragma mark - Utils

+ (void)processResponse:(NSURLResponse * _Nullable)response
               withData:(NSData * _Nullable)data
                  error:(NSError * _Nullable)error
             completion:(PanBaiduNetdiskAPIClientDictionaryBlock _Nullable)completion
{
    NSDictionary *responseDictionary = nil;
    NSError *parsingError = nil;
    if(data){
        responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parsingError];
    }
    NSError *objectValidationError = nil;
    if([responseDictionary isKindOfClass:[NSDictionary class]]==NO){
        responseDictionary = nil;
        objectValidationError = [NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadResponse];
    }
    NSError *resultError = nil;
    NSHTTPURLResponse *HTTPResponse = nil;
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        HTTPResponse = (NSHTTPURLResponse *)response;
    }
    if([response isKindOfClass:[NSHTTPURLResponse class]] && ([HTTPResponse statusCode]>=300 || [HTTPResponse statusCode]<200)){
        resultError = [NSError errorWithDomain:NSURLErrorDomain code:[HTTPResponse statusCode] userInfo:nil];
    }
    else{
        if(error){
            resultError = error;
        }
        else if(parsingError){
            resultError = parsingError;
        }
        else{
            resultError = objectValidationError;
        }
    }
    
    //check server error code in response json
    NSInteger internalErrorCode = [[responseDictionary objectForKey:@"errno"] integerValue];
    if (internalErrorCode != 0) {
        resultError = [NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadResponse internalErrorDictionary:responseDictionary];
        responseDictionary = nil;
    }
    
    if (completion) {
        completion(responseDictionary,resultError);
    }
}

+ (NSError * _Nullable)processResponse:(NSURLResponse * _Nullable)response
                             withError:(NSError * _Nullable)error
                            completion:(PanBaiduNetdiskAPIClientErrorBlock _Nullable)completion
{
    NSHTTPURLResponse *HTTPResponse = nil;
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        HTTPResponse = (NSHTTPURLResponse *)response;
    }
    NSError *resultError = nil;
    if(error){
        resultError = error;
    }
    else if([response isKindOfClass:[NSHTTPURLResponse class]] && ([HTTPResponse statusCode] >= 300 || [HTTPResponse statusCode] < 200)){
        resultError = [NSError errorWithDomain:NSURLErrorDomain code:[HTTPResponse statusCode] userInfo:nil];
    }
    if(completion){
        completion(resultError);
    }
    return resultError;
}

+ (NSURL * _Nullable)processResponseWithURL:(NSURL * _Nullable)url
                                      error:(NSError * _Nullable)error
                                 completion:(PanBaiduNetdiskAPIClientURLBlock _Nullable)completion
{
    if(completion){
        completion(url,error);
    }
    return url;
}

+ (NSData *)createMultipartFormDataBodyWithBoundary:(NSString *)boundary
                                      parameterName:(NSString *)parameterName
                                           fileName:(NSString *)fileName
                                           fileData:(NSData *)fileData
                                           mimeType:(NSString *)mimeType
{
    NSMutableData *httpBody = [NSMutableData data];
    [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", parameterName, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:fileData];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return httpBody;
}

+ (NSData *)createBodyWithURLEncodedParameters:(NSDictionary<NSString *,NSString *> *)parameters {
    NSMutableArray<NSString *> *paramsArray = [NSMutableArray new];
    for (NSString *key in parameters.allKeys) {
        [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", key, parameters[key]]];
    }
    NSString *paramsString = [paramsArray componentsJoinedByString:@"&"];
    NSData *paramsData = [paramsString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    return paramsData;
}

+ (NSMutableArray<NSURLQueryItem *> *)queryItemsFromParameters:(NSDictionary<NSString *,NSString *> *)params {
    NSMutableArray<NSURLQueryItem *> *queryParameters = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:obj];
        [queryParameters addObject:item];
    }];
    return queryParameters;
}

+ (NSString *)URLEncodedParameters:(NSDictionary<NSString *,NSString *> *)params {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.queryItems = [self queryItemsFromParameters:params];
    NSString *encodedQuery = components.percentEncodedQuery;
    // NSURLComponents.percentEncodedQuery creates a validly escaped URL query component, but
    // doesn't encode the '+' leading to potential ambiguity with application/x-www-form-urlencoded
    // encoding. Percent encodes '+' to avoid this ambiguity.
    encodedQuery = [encodedQuery stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    return encodedQuery;
}

+ (NSString *)URLEncodedPath:(NSString *)string {
    NSMutableCharacterSet * charSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [charSet addCharactersInString:@".-_~"];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:charSet];
}

+ (NSURL *)URLByReplacingQueryParameters:(NSDictionary<NSString *,NSString *> *)queryParameters
                                   inURL:(NSURL *)originalURL
{
    NSURLComponents *components =
    [NSURLComponents componentsWithURL:originalURL resolvingAgainstBaseURL:NO];
    
    // Replaces encodedQuery component
    NSString *queryString = [self URLEncodedParameters:queryParameters];
    components.percentEncodedQuery = queryString;
    
    NSURL *URLWithParameters = components.URL;
    return URLWithParameters;
}

+ (NSDictionary *_Nullable)queryDictionaryFromURL:(NSURL *)URL{
    NSMutableDictionary *queryDictionary = [NSMutableDictionary new];
    NSURLComponents *components =
    [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    // As OAuth uses application/x-www-form-urlencoded encoding, interprets '+' as a space
    // in addition to regular percent decoding. https://url.spec.whatwg.org/#urlencoded-parsing
    components.percentEncodedQuery =
    [components.percentEncodedQuery stringByReplacingOccurrencesOfString:@"+"
                                                              withString:@"%20"];
    // NB. @c queryItems are already percent decoded
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    for (NSURLQueryItem *queryItem in queryItems) {
        [queryDictionary setObject:queryItem.value forKey:queryItem.name];
    }
    return queryDictionary;
}

+ (NSString *)createMultipartFormBoundary{
    return [NSString stringWithFormat:@"Boundary-%@",[NSUUID UUID].UUIDString];
}

+ (NSString *_Nullable)accessTokenFromURL:(NSURL *)url {
    NSParameterAssert(url);
    if (url == nil) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"access_token"]) {
            return item.value;
        }
    }
    return nil;
}

+ (void)printRequest:(NSURLRequest *)request{
    PanBaiduNetdiskLog(@"URL: %@\nHEADER_FIELDS:%@\nBODY: %@",request.URL.absoluteString,request.allHTTPHeaderFields,[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
}

@end
