//
//  NSError+MCHSDK.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "NSError+PanBaiduNetdisk.h"

NSString * const PanBaiduNetdiskErrorDomain = @"PanBaiduNetdiskErrorDomain";
NSString * const PanBaiduNetdiskAPIErrorDomain = @"PanBaiduNetdiskAPIErrorDomain";

@implementation NSError(PanBaiduNetdisk)

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode
{
    return [NSError errorWithDomain:PanBaiduNetdiskErrorDomain code:errorCode userInfo:nil];
}

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode
                     internalErrorDictionary:(NSDictionary *)internalErrorDictionary
{
    NSInteger internalErrorCode = [[internalErrorDictionary objectForKey:@"errno"] integerValue];
    NSError *underlyingError = [NSError errorWithDomain:PanBaiduNetdiskAPIErrorDomain code:internalErrorCode userInfo:internalErrorDictionary];
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
    self.code == PanBaiduNetdiskErrorCodeCannotUpdateAccessToken);
    
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
    
    const BOOL isUnderlyingErrorUnauthorized = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 401;
    if (isUnderlyingErrorUnauthorized) {
        return YES;
    }
    
    const BOOL isUnderlyingErrorForbidden = [underlyingError.domain isEqualToString:NSURLErrorDomain] && underlyingError.code == 403;
    if (isUnderlyingErrorForbidden) {
        return YES;
    }
    
    return NO;
}

@end
