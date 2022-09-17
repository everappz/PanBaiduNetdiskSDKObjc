//
//  PanBaiduNetdiskRequestsCache.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduNetdiskAPIClientRequest;
@protocol PanBaiduNetdiskAPIClientCancellableRequest;

@interface PanBaiduNetdiskRequestsCache : NSObject

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cachedCancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier;

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCachedCancellableRequestsWithURLTasks;

- (PanBaiduNetdiskAPIClientRequest *)createCachedCancellableRequest;

- (void)addCancellableRequestToCache:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request;

- (void)removeCancellableRequestFromCache:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request;

- (void)cancelAndRemoveAllCachedRequests;

@end

NS_ASSUME_NONNULL_END
