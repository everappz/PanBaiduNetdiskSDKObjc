//
//  PanBaiduNetdiskRequestsCache.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "PanBaiduNetdiskRequestsCache.h"
#import "PanBaiduNetdiskAPIClientRequest.h"

@interface PanBaiduNetdiskRequestsCache()

@property (nonatomic,strong)NSMutableArray<PanBaiduNetdiskAPIClientCancellableRequest> *cancellableRequests;
@property (nonatomic,strong)NSRecursiveLock *cancellableRequestsLock;

@end


@implementation PanBaiduNetdiskRequestsCache

- (instancetype)init{
    self = [super init];
    if(self){
        self.cancellableRequests = [NSMutableArray<PanBaiduNetdiskAPIClientCancellableRequest> new];
        self.cancellableRequestsLock = [NSRecursiveLock new];
    }
    return self;
}

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier{
    __block PanBaiduNetdiskAPIClientRequest *clientRequest = nil;
    [self.cancellableRequestsLock lock];
    [self.cancellableRequests enumerateObjectsUsingBlock:^(id<PanBaiduNetdiskAPIClientCancellableRequest>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[PanBaiduNetdiskAPIClientRequest class]] && ((PanBaiduNetdiskAPIClientRequest *)obj).URLTaskIdentifier==URLTaskIdentifier){
            clientRequest = obj;
            *stop = YES;
        }
    }];
    [self.cancellableRequestsLock unlock];
    return clientRequest;
}

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks{
    NSMutableArray *result = [NSMutableArray new];
    [self.cancellableRequestsLock lock];
    [self.cancellableRequests enumerateObjectsUsingBlock:^(id<PanBaiduNetdiskAPIClientCancellableRequest>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[PanBaiduNetdiskAPIClientRequest class]] && ((PanBaiduNetdiskAPIClientRequest *)obj).URLTaskIdentifier>0){
            [result addObject:obj];
        }
    }];
    [self.cancellableRequestsLock unlock];
    return result;
}

- (PanBaiduNetdiskAPIClientRequest *)createAndAddCancellableRequest{
    PanBaiduNetdiskAPIClientRequest *clientRequest = [[PanBaiduNetdiskAPIClientRequest alloc] init];
    [self addCancellableRequest:clientRequest];
    return clientRequest;
}

- (void)addCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    NSParameterAssert([request conformsToProtocol:@protocol(PanBaiduNetdiskAPIClientCancellableRequest)]);
    if([request conformsToProtocol:@protocol(PanBaiduNetdiskAPIClientCancellableRequest)]){
        [self.cancellableRequestsLock lock];
        [self.cancellableRequests addObject:request];
        [self.cancellableRequestsLock unlock];
    }
}

- (void)removeCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request{
    NSParameterAssert(request==nil || [request conformsToProtocol:@protocol(PanBaiduNetdiskAPIClientCancellableRequest)]);
    if([request conformsToProtocol:@protocol(PanBaiduNetdiskAPIClientCancellableRequest)]){
        [self.cancellableRequestsLock lock];
        [self.cancellableRequests removeObject:request];
        [self.cancellableRequestsLock unlock];
    }
}

@end
