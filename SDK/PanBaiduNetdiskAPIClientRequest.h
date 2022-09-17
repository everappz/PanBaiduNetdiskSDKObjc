//
//  PanBaiduNetdiskAPIClientRequest.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PanBaiduNetdiskAPIClientCancellableRequest <NSObject>

- (void)cancel;

@end



@interface PanBaiduNetdiskAPIClientRequest : NSObject <PanBaiduNetdiskAPIClientCancellableRequest>

- (instancetype)initWithInternalRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)internalRequest;

@property (nonatomic,strong,nullable) id<PanBaiduNetdiskAPIClientCancellableRequest> internalRequest;
@property (nonatomic, copy, nullable) PanBaiduNetdiskAPIClientDidReceiveDataBlock didReceiveDataBlock;
@property (nonatomic, copy, nullable) PanBaiduNetdiskAPIClientDidReceiveResponseBlock didReceiveResponseBlock;
@property (nonatomic, copy, nullable) PanBaiduNetdiskAPIClientErrorBlock errorCompletionBlock;
@property (nonatomic, copy, nullable) PanBaiduNetdiskAPIClientProgressBlock progressBlock;
@property (nonatomic, copy, nullable) PanBaiduNetdiskAPIClientURLBlock downloadCompletionBlock;
@property (nonatomic , copy , nullable) PanBaiduNetdiskAPIClientVoidBlock cancelBlock;
@property (nonatomic, strong, nullable) NSNumber *totalContentSize;
@property (nonatomic, assign) NSUInteger URLTaskIdentifier;

- (BOOL)isCancelled;

@end


NS_ASSUME_NONNULL_END
