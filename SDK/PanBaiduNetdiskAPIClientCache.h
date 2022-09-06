//
//  PanBaiduNetdiskAPIClientCache.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/20/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduNetdiskAPIClient;
@class PanBaiduNetdiskAuthState;

@interface PanBaiduNetdiskAPIClientCache : NSObject

+ (instancetype)sharedCache;

- (PanBaiduNetdiskAPIClient *_Nullable)clientForIdentifier:(NSString *_Nonnull)identifier;

- (PanBaiduNetdiskAPIClient *_Nullable)createClientForIdentifier:(NSString *_Nonnull)identifier
                                           authState:(PanBaiduNetdiskAuthState *_Nonnull)authState
                                sessionConfiguration:(NSURLSessionConfiguration * _Nullable)URLSessionConfiguration;

- (void)updateAuthState:(PanBaiduNetdiskAuthState *_Nonnull)authState
          forIdentifier:(NSString *_Nonnull)identifier;

@end

NS_ASSUME_NONNULL_END
