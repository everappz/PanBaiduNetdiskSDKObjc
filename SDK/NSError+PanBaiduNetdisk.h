//
//  NSError+MCHSDK.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/17/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, PanBaiduNetdiskErrorCode) {
    PanBaiduNetdiskErrorCodeCancelled = -999,
    PanBaiduNetdiskErrorCodeNone = 0,
    PanBaiduNetdiskErrorCodeCannotGetAuthURL,
    PanBaiduNetdiskErrorCodeAuthFailed,
    PanBaiduNetdiskErrorCodeCannotGetAccessToken,
    PanBaiduNetdiskErrorCodeAccessTokenExpired,
    PanBaiduNetdiskErrorCodeAccessTokenInvalid,
    PanBaiduNetdiskErrorCodeCannotUpdateAccessToken,
    PanBaiduNetdiskErrorCodeAuthProviderIsNil,
    PanBaiduNetdiskErrorCodeBadInputParameters,
    PanBaiduNetdiskErrorCodeBadResponse,
    PanBaiduNetdiskErrorCodeCannotGetDirectURL,
    PanBaiduNetdiskErrorCodeLocalFileNotFound,
    PanBaiduNetdiskErrorCodeLocalFileEmpty,
    PanBaiduNetdiskErrorCodeSafariOpenError,
    PanBaiduNetdiskErrorCodeCancelledAuthorizationFlow,
    PanBaiduNetdiskErrorCodeAccessDenied,
    PanBaiduNetdiskErrorCodeTooManyRequests,
    PanBaiduNetdiskErrorCodeCannotPrepareRequest,
};


/*
0    request succeeded
                        You succeeded.

2    Parameter error
                        1. Check whether all the required parameters have been filled in;
                        2. Check the position of the parameters, some parameters are in the url, some are in the body;
                        3. Check whether the value of each parameter is correct.

111    access token invalid
                                Update access token.

-6    Authentication failed
                                1. Whether the access_token is valid;
                                2. Whether the authorization is successful;
                                3. Refer to the access authorization FAQ ;
                                4. Read the chapter
                                "Getting Started -> Access Authorization " in the document.

6    No access to user data
                                It is recommended that users retry authorization after 10 minutes.

31034    Hit interface frequency control
                                Interface requests are too frequent, pay attention to control.
*/

typedef NS_ENUM(NSInteger, PanBaiduNetdiskPublicAPIErrorCode) {
    PanBaiduNetdiskPublicAPIErrorCodeRequestSucceeded = 0,
    PanBaiduNetdiskPublicAPIErrorCodeParameterError = 2,
    PanBaiduNetdiskPublicAPIErrorCodeAccessTokenInvalid = 111,
    PanBaiduNetdiskPublicAPIErrorCodeAuthenticationFailed = -6,
    PanBaiduNetdiskPublicAPIErrorCodeNoAccessToUserData = 6,
    PanBaiduNetdiskPublicAPIErrorCodeHitInterfaceFrequencyControl = 31034,
};

/*
3. OAuth2.0 error code list
error code    error message    Detailed Description
invalid_request    invalid refresh token    The request is missing a required parameter, contains an unsupported parameter or parameter value, or is malformed.
invalid_client    unknown client id    The "client_id", "client_secret" parameters are invalid.
invalid_grant    The provided authorization grant is revoked    The provided Access Grant is invalid, expired or revoked. For example, the Authorization Code is invalid (one authorization code can only be used once), the Refresh Token is invalid, the redirect_uri is inconsistent with the one provided when obtaining the Authorization Code, and the Devie Code is invalid (one device The authorization code can only be used once), etc.
unauthorized_client    The client is not authorized to use this authorization grant type    The application is not authorized to use the specified grant_type.
unsupported_grant_type    The authorization grant type is not supported    "grant_type" Baidu OAuth2.0 service does not support this parameter.
invalid_scope    The requested scope is exceeds the scope granted by the resource owner    The requested 'scope' parameter is invalid, unknown, malformed, or the requested permission scope exceeds the permission scope granted by the data owner.
expired_token    refresh token has been used    The provided Refresh Token has expired
redirect_uri_mismatch    Invalid redirect uri    The root domain where "redirect_uri" is located does not match the root domain name entered by the developer when registering the app.
unsupported_response_type    The response type is not supported    The "response_type" parameter value is not supported by Baidu OAuth2.0 service, or the application has actively disabled the corresponding authorization mode
slow_down    The device is polling too frequently    In Device Flow, the interface for the device to exchange Device Code for Access Token is too frequent, and the interval between two attempts should be greater than 5 seconds.
authorization_pending    User has not yet completed the authorization    In Device Flow, the user has not completed the authorization operation for the Device Code.
authorization_declined    User has declined the authorization    In Device Flow, the user rejected the authorization operation for Device Code.
invalid_referer    Invalid Referer    In Implicit Grant mode, the Referer requested by the browser does not match the binding of the root domain name
*/


/*
4. OpenAPI error code list
error code    error message    Detailed Description
1    Unknown error    Unknown error, if this error occurs frequently, please contact developer_support@baidu.com
2    Service temporarily unavailable    Service is temporarily unavailable
3    Unsupported openapi method    Access URL error, the interface cannot be accessed
4    Open api request limit reached    The QPS of the APP accessing this interface has reached the upper limit
5    Unauthorized client IP address    The accessed client IP is not in the whitelist
6    No permission to access data    The APP does not have permission to access this interface
17    Open api daily request limit reached    The APP access to this interface exceeds the daily access limit
18    Open api qps request limit reached    The APP accessing this interface exceeds the QPS limit
19    Open api total request limit reached    The APP access to this interface exceeds the total limit
100    Invalid parameter    The token parameter was not obtained
110    Access token invalid or no longer valid    token is not legal
111    Access token expired    token expired
213    No permission to access user mobile    No permission to get user phone number
*/

typedef NS_ENUM(NSInteger, PanBaiduNetdiskOpenAPIErrorCode) {
    PanBaiduNetdiskOpenAPIErrorCodeUnknown = 1,
    PanBaiduNetdiskOpenAPIErrorCodeServiceTemporarilyUnavailable = 2,
    PanBaiduNetdiskOpenAPIErrorCodeUnsupportedMethod = 3,
    PanBaiduNetdiskOpenAPIErrorCodeRequestLimitReached = 4,
    PanBaiduNetdiskOpenAPIErrorCodeUnauthorizedClientIPAddress = 5,
    PanBaiduNetdiskOpenAPIErrorCodeNoPermissionToAccessData = 6,
    PanBaiduNetdiskOpenAPIErrorCodeDailyRequestLimitReached = 17,
    PanBaiduNetdiskOpenAPIErrorCodeQPSRequestLimitReached = 18,
    PanBaiduNetdiskOpenAPIErrorCodeTotalRequestLimiReached = 19,
    PanBaiduNetdiskOpenAPIErrorCodeInvalidParameter = 100,
    PanBaiduNetdiskOpenAPIErrorCodeAccessTokenIvalidOrNoLongerValid = 110,
    PanBaiduNetdiskOpenAPIErrorCodeAccessTokenExpired = 111,
    PanBaiduNetdiskOpenAPIErrorCodeNoPermissionToAccessUserMobile = 213,
};


/*
Error code format
When the user has an error accessing the API, the corresponding error code and error information will be returned to the user, which is convenient for locating the problem and making appropriate processing. When an error occurs in the request, the detailed error information is returned through Response Body, which follows the following format:

parameter name    type    illustrate
errno    String    Indicates the specific error code.
errmsg    String    A description of the error.
request_id    String    The request id that initiated the request.
E.g:

 {
    "errno": -6,
    "errmsg": "Invalid Bduss",
    "request_id": "8889392513333350895"
}
*/

extern  NSString * const PanBaiduNetdiskErrorDomain;

@interface NSError (PanBaiduNetdisk)

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode;

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode internalErrorDictionary:(NSDictionary *)internalErrorDictionary;

+ (instancetype)panBaiduNetdiskErrorWithCode:(NSInteger)errorCode internalError:(NSError *)internalError;

- (BOOL)isPanBaiduNetdiskTooManyRequestsError;

- (BOOL)isPanBaiduNetdiskAuthError;

@end

NS_ASSUME_NONNULL_END

