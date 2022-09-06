//
//  PanBaiduNetdiskAccessToken.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 3/12/21.
//

#import "PanBaiduNetdiskAccessToken.h"

@interface PanBaiduNetdiskAccessToken ()

@property (nonatomic,copy)NSString *token;

@property (nonatomic,copy)NSDate *tokenExpireDate;

@end


@implementation PanBaiduNetdiskAccessToken

+ (instancetype)accessTokenWithToken:(NSString *)token
                     tokenExpireDate:(NSDate *)tokenExpireDate
{
    NSParameterAssert(token);
    if(token == nil){
        return nil;
    }
    PanBaiduNetdiskAccessToken *accessToken = [PanBaiduNetdiskAccessToken new];
    accessToken.token = token;
    accessToken.tokenExpireDate = tokenExpireDate;
    return accessToken;
}

@end
