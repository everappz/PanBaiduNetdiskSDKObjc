//
//  PanBaiduNetdiskAuthState.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>
#import "PanBaiduNetdiskConstants.h"
#import "PanBaiduNetdiskAccessToken.h"

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduNetdiskAuthState;

@protocol PanBaiduNetdiskAuthStateChangeDelegate <NSObject>

- (void)panBaiduNetdiskAuthStateDidChange:(PanBaiduNetdiskAuthState *)state;

@end


@interface PanBaiduNetdiskAuthState : NSObject

- (instancetype)initWithToken:(PanBaiduNetdiskAccessToken * _Nullable)token;

@property (nonatomic, readonly, strong, nullable) PanBaiduNetdiskAccessToken *token;

@property (nonatomic, weak, nullable) id<PanBaiduNetdiskAuthStateChangeDelegate> stateChangeDelegate;

- (NSURLSessionDataTask *_Nullable)updateTokenWithCompletion:(PanBaiduNetdiskAccessTokenUpdateBlock)completion;

@end

NS_ASSUME_NONNULL_END
