//
//  NSError+MCHSDK.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import "NSError+PanBaiduNetdisk.h"

NSString * const PanBaiduNetdiskErrorDomain = @"PanBaiduNetdiskErrorDomain";
NSString * const PanBaiduNetdiskAPIErrorDomain = @"PanBaiduNetdiskAPIErrorDomain";
NSString * const PanBaiduNetdiskAPIErrorDictionary = @"PanBaiduNetdiskAPIErrorDictionary";

@implementation NSError(PanBaiduNetdisk)

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode
{
    return [NSError errorWithDomain:PanBaiduNetdiskErrorDomain code:errorCode userInfo:nil];
}

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode
                               internalError:(NSError *)internalError
{
    NSDictionary *userInfo = internalError?@{NSUnderlyingErrorKey:internalError}:nil;
    return [NSError errorWithDomain:PanBaiduNetdiskErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode
                     internalErrorDictionary:(NSDictionary *)internalErrorDictionary
{
    NSInteger internalErrorCode = [[internalErrorDictionary objectForKey:@"errno"] integerValue];
    NSString *internalErrorMessage = [internalErrorDictionary objectForKey:@"errmsg"]?:@"";
    
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (internalErrorDictionary) {
        [userInfo setObject:internalErrorDictionary forKey:PanBaiduNetdiskAPIErrorDictionary];
    }
    if (internalErrorMessage) {
        [userInfo setObject:internalErrorMessage forKey:NSLocalizedDescriptionKey];
    }
    
    NSInteger resultErrorCode = errorCode;
    
    if (internalErrorCode == PanBaiduNetdiskPublicAPIErrorCodeParameterError) {
        resultErrorCode = PanBaiduNetdiskErrorCodeBadInputParameters;
    }
    else if (internalErrorCode == PanBaiduNetdiskPublicAPIErrorCodeAccessTokenInvalid) {
        resultErrorCode = PanBaiduNetdiskErrorCodeAccessTokenInvalid;
    }
    else if (internalErrorCode == PanBaiduNetdiskPublicAPIErrorCodeAuthenticationFailed) {
        resultErrorCode = PanBaiduNetdiskErrorCodeAuthFailed;
    }
    else if (internalErrorCode == PanBaiduNetdiskPublicAPIErrorCodeNoAccessToUserData) {
        resultErrorCode = PanBaiduNetdiskErrorCodeAccessDenied;
    }
    else if (internalErrorCode == PanBaiduNetdiskPublicAPIErrorCodeHitInterfaceFrequencyControl) {
        resultErrorCode = PanBaiduNetdiskErrorCodeTooManyRequests;
    }
    
    NSError *underlyingError = [NSError errorWithDomain:PanBaiduNetdiskAPIErrorDomain code:internalErrorCode userInfo:userInfo];
    return [NSError errorWithDomain:PanBaiduNetdiskErrorDomain code:errorCode userInfo:@{NSUnderlyingErrorKey:underlyingError}];
}

- (BOOL)isPanBaiduNetdiskTooManyRequestsError{
    return [self.domain isEqualToString:NSURLErrorDomain] && self.code == 429;
}

- (BOOL)isPanBaiduNetdiskAuthError{
    
    const BOOL accessTokenInvalid =
    [self.domain isEqualToString:PanBaiduNetdiskErrorDomain] &&
    (self.code == PanBaiduNetdiskErrorCodeCannotGetAuthURL ||
     self.code == PanBaiduNetdiskErrorCodeCannotGetAccessToken ||
     self.code == PanBaiduNetdiskErrorCodeAccessTokenExpired ||
     self.code == PanBaiduNetdiskErrorCodeAccessTokenInvalid ||
     self.code == PanBaiduNetdiskErrorCodeCannotUpdateAccessToken ||
     self.code == PanBaiduNetdiskPublicAPIErrorCodeAuthenticationFailed);
    
    if (accessTokenInvalid) {
        return YES;
    }
    
    const BOOL isUnauthorizedError = [self.domain isEqualToString:NSURLErrorDomain] && self.code == 401;
    if (isUnauthorizedError) {
        return YES;
    }
    
    const BOOL isForbiddenError = [self.domain isEqualToString:NSURLErrorDomain] && self.code == 403;
    if (isForbiddenError) {
        return YES;
    }
    
    NSError *underlyingError = [self.userInfo objectForKey:NSUnderlyingErrorKey];
    
    const BOOL isUnderlyingURLErrorUnauthorized = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 401;
    if (isUnderlyingURLErrorUnauthorized) {
        return YES;
    }
    
    const BOOL isUnderlyingURLErrorForbidden = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 403;
    if (isUnderlyingURLErrorForbidden) {
        return YES;
    }
    
    const BOOL isUnderlyingErrorNetDiskAccessTokenInvalid =
    [underlyingError.domain isEqualToString:PanBaiduNetdiskAPIErrorDomain] &&
    (underlyingError.code == PanBaiduNetdiskPublicAPIErrorCodeAccessTokenInvalid ||
     underlyingError.code == PanBaiduNetdiskPublicAPIErrorCodeAuthenticationFailed);
    if (isUnderlyingErrorNetDiskAccessTokenInvalid) {
        return YES;
    }
    
    return NO;
}

@end
