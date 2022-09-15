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

- (PanBaiduNetdiskAPIClientRequest * _Nullable)cancellableRequestWithURLTaskIdentifier:(NSUInteger)URLTaskIdentifier;

- (NSArray<PanBaiduNetdiskAPIClientRequest *> * _Nullable)allCancellableRequestsWithURLTasks;

- (PanBaiduNetdiskAPIClientRequest *)createAndAddCancellableRequest;

- (void)addCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request;

- (void)removeCancellableRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nonnull)request;

- (void)cancelAndRemoveAllRequests;

@end

NS_ASSUME_NONNULL_END
