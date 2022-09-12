//
//  PanBaiduAppAuthProvider.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"


@class PanBaiduNetdiskAuthState;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const PanBaiduAppAuthProviderDidChangeState;

@interface PanBaiduAppAuthProvider : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier state:(PanBaiduNetdiskAuthState *)authState;

@property (nonatomic, strong, readonly) PanBaiduNetdiskAuthState *authState;

@property (nonatomic, copy, readonly) NSString *identifier;

- (void)getAccessTokenWithCompletionBlock:(PanBaiduNetdiskAccessTokenGetBlock)completion;

- (NSURLSessionDataTask * _Nullable)updateAccessTokenWithCompletionBlock:(PanBaiduNetdiskAccessTokenUpdateBlock)completion;

@end

NS_ASSUME_NONNULL_END
