//
//  MCHNetwork.m
//  MyCloudHomeSDKObjc
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
    if (self){
        NSURLSessionConfiguration *resultConfiguration = URLSessionConfiguration;
        if(resultConfiguration == nil){
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
                                        contentType:(NSString * _Nullable)contentType
                                        accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self requestWithURL:requestURL
                         method:@"GET"
                    contentType:contentType
                    accessToken:accessToken];
}

- (NSMutableURLRequest *_Nullable)DELETERequestWithURL:(NSURL *)requestURL
                                           contentType:(NSString *)contentType
                                           accessToken:(PanBaiduNetdiskAccessToken * _Nullable)accessToken
{
    return [self requestWithURL:requestURL
                         method:@"DELETE"
                    contentType:contentType
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
                                        contentType:(NSString *)contentType
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
    
    NSString *type = nil;
    NSString *token = nil;
    NSString *authorizationHeader = nil;
    NSURL *requestURLModified = requestURL;
    
    if (accessToken) {
        token = accessToken.token;
        NSParameterAssert(token);
        if (type == nil || type.length == 0) {
            type = @"Bearer";
        }
        authorizationHeader = [NSString stringWithFormat:@"%@ %@",type,token];
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:requestURL.absoluteString];
    NSString *accessTokenStringFromComponents = nil;
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"access_token"]) {
            accessTokenStringFromComponents = item.value;
        }
    }
    
    if (accessTokenStringFromComponents == nil && token != nil) {
        NSMutableArray *queryItemsUpdated = [components.queryItems mutableCopy];
        NSURLQueryItem *accessTokenItem = [NSURLQueryItem queryItemWithName:@"access_token" value:token];
        [queryItemsUpdated addObject:accessTokenItem];
        components.queryItems = queryItemsUpdated;
        requestURLModified = components.URL;
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURLModified];
    [request setHTTPMethod:method];
    
    if (authorizationHeader) {
        [request addValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
    }
    
    if (contentType) {
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
    
    return request;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session dataTaskWithRequest:request
                               completionHandler:completionHandler];
    }
    if(completionHandler){
        completionHandler(nil,nil,[NSError panBaiduNetdiskErrorWithCode:PanBaiduNetdiskErrorCodeBadInputParameters]);
    }
    return nil;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session dataTaskWithRequest:request];
    }
    return nil;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session downloadTaskWithRequest:request];
    }
    return nil;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL{
    NSParameterAssert(self.session);
    NSParameterAssert(request);
    if(self.session && request){
        return [self.session uploadTaskWithRequest:request fromFile:fileURL];
    }
    return nil;
}

#pragma mark - NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(nullable NSError *)error
{
    NSArray *tasks = [self allCancellableRequestsWithURLTasks];
    [tasks enumerateObjectsUsingBlock:^(PanBaiduNetdiskAPIClientRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.errorCompletionBlock){
            obj.errorCompletionBlock(error);
        }
        [self removeCancellableRequest:obj];
    }];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    PanBaiduNetdiskAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:task.taskIdentifier];
    int64_t totalSize = totalBytesExpectedToSend>0?totalBytesExpectedToSend:[request.totalContentSize longLongValue];
    if (request.progressBlock && totalSize > 0) {
        request.progressBlock((float)totalBytesSent/(float)totalSize);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    PanBaiduNetdiskAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:task.taskIdentifier];
    if(request.errorCompletionBlock){
        request.errorCompletionBlock(error);
    }
    if(request.downloadCompletionBlock){
        request.downloadCompletionBlock(nil,error);
    }
    [self removeCancellableRequest:request];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    PanBaiduNetdiskAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:dataTask.taskIdentifier];
    if(request.didReceiveResponseBlock){
        request.didReceiveResponseBlock(response);
    }
    if(completionHandler){
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    PanBaiduNetdiskAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:dataTask.taskIdentifier];
    if(request.didReceiveDataBlock){
        request.didReceiveDataBlock(data);
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    PanBaiduNetdiskAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:downloadTask.taskIdentifier];
    if(request.downloadCompletionBlock){
        request.downloadCompletionBlock(location,nil);
    }
    [self removeCancellableRequest:request];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    PanBaiduNetdiskAPIClientRequest *request = [self cancellableRequestWithURLTaskIdentifier:downloadTask.taskIdentifier];
    int64_t totalSize = totalBytesExpectedToWrite>0?totalBytesExpectedToWrite:[request.totalContentSize longLongValue];
    if(request.progressBlock && totalSize>0){
        request.progressBlock((float)totalBytesWritten/(float)totalSize);
    }
}

#pragma mark - Requests Cache

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier{
    return [self.requestsCache cancellableRequestWithURLTaskIdentifier:URLTaskIdentifier];
}

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks{
    return [self.requestsCache allCancellableRequestsWithURLTasks];
}

- (PanBaiduNetdiskAPIClientRequest *)createAndAddCancellableRequest{
    return [self.requestsCache createAndAddCancellableRequest];
}

- (void)addCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.requestsCache addCancellableRequest:request];
}

- (void)removeCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    return [self.requestsCache removeCancellableRequest:request];
}

#pragma mark - Internal

+ (void)processDictionaryCompletion:(PanBaiduNetdiskAPIClientDictionaryCompletionBlock)completion
                           withData:(NSData * _Nullable)data
                           response:(NSURLResponse * _Nullable)response
                              error:(NSError * _Nullable)error{
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
    if(completion){
        completion(responseDictionary,resultError);
    }
}

+ (NSError * _Nullable)processErrorCompletion:(PanBaiduNetdiskAPIClientErrorCompletionBlock)completion
                                     response:(NSURLResponse * _Nullable)response
                                        error:(NSError * _Nullable)error{
    NSHTTPURLResponse *HTTPResponse = nil;
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        HTTPResponse = (NSHTTPURLResponse *)response;
    }
    NSError *resultError = nil;
    if(error){
        resultError = error;
    }
    else if([response isKindOfClass:[NSHTTPURLResponse class]] && ([HTTPResponse statusCode]>=300 || [HTTPResponse statusCode]<200)){
        resultError = [NSError errorWithDomain:NSURLErrorDomain code:[HTTPResponse statusCode] userInfo:nil];
    }
    if(completion){
        completion(resultError);
    }
    return resultError;
}

+ (NSURL * _Nullable)processURLCompletion:(PanBaiduNetdiskAPIClientURLCompletionBlock)completion
                                      url:(NSURL * _Nullable)url
                                    error:(NSError * _Nullable)error{
    if(completion){
        completion(url,error);
    }
    return url;
}

+ (NSData *)createMultipartRelatedBodyWithBoundary:(NSString *)boundary
                                        parameters:(NSDictionary<NSString *,NSString *> *)parameters {
    NSMutableData *httpBody = [NSMutableData data];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"{" dataUsingEncoding:NSUTF8StringEncoding]];
    __block NSUInteger index = 0;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        NSString *separator = (index<(parameters.count-1))?@",":@"";
        [httpBody appendData:[[NSString stringWithFormat:@"\"%@\":\"%@\"%@", parameterKey, parameterValue,separator] dataUsingEncoding:NSUTF8StringEncoding]];
        index++;
    }];
    [httpBody appendData:[@"}" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return httpBody;
}

+ (NSData *)createJSONBodyWithParameters:(NSDictionary<NSString *,NSString *> *)parameters {
    NSMutableData *httpBody = [NSMutableData data];
    [httpBody appendData:[@"{" dataUsingEncoding:NSUTF8StringEncoding]];
    __block NSUInteger index = 0;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        NSString *separator = (index<(parameters.count-1))?@",":@"";
        [httpBody appendData:[[NSString stringWithFormat:@"\"%@\":\"%@\"%@", parameterKey, parameterValue,separator] dataUsingEncoding:NSUTF8StringEncoding]];
        index++;
    }];
    [httpBody appendData:[@"}" dataUsingEncoding:NSUTF8StringEncoding]];
    return httpBody;
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

+ (NSURL *)URLByReplacingQueryParameters:(NSDictionary<NSString *,NSString *> *)queryParameters inURL:(NSURL *)originalURL {
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
    return [NSString stringWithFormat:@"foo%08X%08X", arc4random(), arc4random()];
}

+ (void)printRequest:(NSURLRequest *)request{
    NSLog(@"URL: %@\nHEADER_FIELDS:%@\nBODY: %@",request.URL.absoluteString,
          request.allHTTPHeaderFields,
          [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
}

@end
