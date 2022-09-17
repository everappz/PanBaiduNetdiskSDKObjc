//
//  PanBaiduNetdiskRequestsCache.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "PanBaiduNetdiskRequestsCache.h"
#import "PanBaiduNetdiskAPIClientRequest.h"

@interface PanBaiduNetdiskRequestsCache()

@property (nonatomic,strong)NSMutableArray<PanBaiduNetdiskAPIClientCancellableRequest> *cancellableRequests;

@property (nonatomic,strong)NSRecursiveLock *stateLock;

@end


@implementation PanBaiduNetdiskRequestsCache

- (instancetype)init {
    self = [super init];
    if(self){
        self.cancellableRequests = [NSMutableArray<PanBaiduNetdiskAPIClientCancellableRequest> new];
        self.stateLock = [NSRecursiveLock new];
    }
    return self;
}

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier {
    __block PanBaiduNetdiskAPIClientRequest *clientRequest = nil;
    [self.stateLock lock];
    [self.cancellableRequests enumerateObjectsUsingBlock:^(id<PanBaiduNetdiskAPIClientCancellableRequest>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[PanBaiduNetdiskAPIClientRequest class]] &&
            ((PanBaiduNetdiskAPIClientRequest *)obj).URLTaskIdentifier == URLTaskIdentifier)
        {
            clientRequest = obj;
            *stop = YES;
        }
    }];
    [self.stateLock unlock];
    return clientRequest;
}

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks{
    NSMutableArray *result = [NSMutableArray new];
    [self.stateLock lock];
    for (id<PanBaiduNetdiskAPIClientCancellableRequest> obj in self.cancellableRequests) {
        if ([obj isKindOfClass:[PanBaiduNetdiskAPIClientRequest class]] &&
            ((PanBaiduNetdiskAPIClientRequest *)obj).URLTaskIdentifier > 0)
        {
            [result addObject:obj];
        }
    }
    [self.stateLock unlock];
    return result;
}

- (PanBaiduNetdiskAPIClientRequest *)createAndAddCancellableRequest{
    PanBaiduNetdiskAPIClientRequest *clientRequest = [[PanBaiduNetdiskAPIClientRequest alloc] init];
    PanBaiduNetdiskMakeWeakSelf;
    PanBaiduNetdiskMakeWeakReference(clientRequest);
    [clientRequest setCancelBlock:^{
        [weakSelf removeCancellableRequest:weak_clientRequest];
    }];
    [self addCancellableRequest:clientRequest];
    return clientRequest;
}

- (void)addCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    NSParameterAssert([request conformsToProtocol:@protocol(PanBaiduNetdiskAPIClientCancellableRequest)]);
    if ([request conformsToProtocol:@protocol(PanBaiduNetdiskAPIClientCancellableRequest)] == NO) {
        return;
    }
    [self.stateLock lock];
    [self.cancellableRequests addObject:request];
    NSParameterAssert(self.cancellableRequests.count < 100);
    [self.stateLock unlock];
}

- (void)removeCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    if ([request isKindOfClass:[PanBaiduNetdiskAPIClientRequest class]]) {
        PanBaiduNetdiskAPIClientRequest *clientRequest = (PanBaiduNetdiskAPIClientRequest *)request;
        [self removeCancellableRequest:clientRequest.internalRequest];
    }
    
    if ([request conformsToProtocol:@protocol(PanBaiduNetdiskAPIClientCancellableRequest)]) {
        [self.stateLock lock];
        [self.cancellableRequests removeObject:request];
        [self.stateLock unlock];
    }
}

- (void)cancelAndRemoveAllRequests {
    [self.stateLock lock];
    for (id<PanBaiduNetdiskAPIClientCancellableRequest>request in self.cancellableRequests) {
        [PanBaiduNetdiskRequestsCache removeCancelBlockForRequest:request];
        if ([request respondsToSelector:@selector(cancel)]) {
        [request cancel];
        }
    }
    [self.cancellableRequests removeAllObjects];
    [self.stateLock unlock];
}

+ (void)removeCancelBlockForRequest:(id)request {
    if ([request isKindOfClass:[PanBaiduNetdiskAPIClientRequest class]] == NO) {
        return;
    }
    PanBaiduNetdiskAPIClientRequest *clientRequest = (PanBaiduNetdiskAPIClientRequest *)request;
    [clientRequest setCancelBlock:nil];
    [PanBaiduNetdiskRequestsCache removeCancelBlockForRequest:clientRequest.internalRequest];
}

@end
