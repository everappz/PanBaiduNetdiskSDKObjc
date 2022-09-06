//
//  PanBaiduNetdiskAccessToken.h
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PanBaiduNetdiskAccessToken : NSObject

@property (nonatomic,copy,readonly)NSString *token;

@property (nonatomic,copy,readonly)NSDate *tokenExpireDate;

+ (instancetype)accessTokenWithToken:(NSString *)token tokenExpireDate:(NSDate *)tokenExpireDate;

@end

NS_ASSUME_NONNULL_END
