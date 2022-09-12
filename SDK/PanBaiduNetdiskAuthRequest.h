//
//  PanBaiduNetdiskAuthRequest.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/10/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



//https://pan.baidu.com/union/doc/al0rwqzzl

/*
 
 Briefly describe the process of the timing chart, as follows:
 
 1. Users choose to log in to the developer app through Baidu account.
 
 2. The developer app initiates an authorization code code request.
 
 3. Baidu OAuth server displays the authorization page to the user, who logs in and agrees to the authorization.
 
 4. After the user agrees to the authorization, Baidu OAuth server will jump the page to the callback address configured by the developer application and return the authorization code code code.
 
 5. The developer app initiates a Code in exchange for a Access Token request.
 
 6. Baidu OAuth server returns Access Token credentials.
 
 */



@interface PanBaiduNetdiskAuthRequest : NSObject

- (NSURLRequest * _Nullable)URLRequest;

@property (nonatomic,strong)NSURL *requestURL;

@end

/*
 GET http://openapi.baidu.com/oauth/2.0/authorize?
 response_type=code&
 client_id=您应用的AppKey&
 redirect_uri=您应用的授权回调地址&
 scope=basic,netdisk&
 device_id=您应用的AppID&
 display=mobile
 */


@interface PanBaiduNetdiskAuthorizationCodeRequest : PanBaiduNetdiskAuthRequest

+ (instancetype)requestWithClientID:(NSString *)clientID
                        redirectURI:(NSString *)redirectURI
                              scope:(NSString *)scope
                           deviceID:(NSString *)deviceID
                       responseType:(NSString *)responseType
                            display:(NSString *)display;

@property (nonatomic,copy,readonly)NSString *clientID;
@property (nonatomic,copy,readonly)NSString *scope;//Fixed value, the value must be basic, netdisk.
@property (nonatomic,copy,readonly)NSString *redirectURI;
@property (nonatomic,copy,readonly)NSString *deviceID;
@property (nonatomic,copy,readonly)NSString *responseType;
@property (nonatomic,copy,readonly)NSString *display;

@end




/*
 GET https://openapi.baidu.com/oauth/2.0/token?
 grant_type=authorization_code&
 code=用户授权码 Code 值&
 client_id=您应用的AppKey&
 client_secret=您应用的SecretKey&
 redirect_uri=您应用设置的授权回调地址
 */

/*
 {
 expires_in: 2592000,
 refresh_token: "122.2582432a1cf40bc91ca31c10b5a6c038.Y3l6ETFhyjmS8ABFNRv3cPcJzKO-Pl9M4TCnUpx.LHh1Vw",
 access_token: "121.fd4b4277dba7a65a51cf370d0e83f567.Y74pa1cYlIOT_Vdp2xuWOqeasckh1tWtxT9Ouw5.LPOBOA",
 session_secret: "",
 session_key: "",
 scope: "basic netdisk"
 }
 
 The return value is described as follows:
 
 Parameters    Type    Notes
 access_token    string    Access Token, which is the certificate that calls the network disk open API to access user-authorized resources.
 expires_in    int    Access Token is valid in seconds.
 refresh_token    string    It is used to refresh Access Token, which is valid for 10 years.
 scope    string    Access Token's final access, that is, the list of the user's actual authorizations.
 
 */

@interface PanBaiduNetdiskTokenExchangeRequest : PanBaiduNetdiskAuthRequest

+ (instancetype)requestWithClientID:(NSString *)clientID
                       clientSecret:(NSString *)clientSecret
                        redirectURI:(NSString *)redirectURI
                          grantType:(NSString *)grantType
                               code:(NSString *)code;

@property (nonatomic,copy,readonly)NSString *clientID;
@property (nonatomic,copy,readonly)NSString *clientSecret;
@property (nonatomic,copy,readonly)NSString *redirectURI;
@property (nonatomic,copy,readonly)NSString *grantType;
@property (nonatomic,copy,readonly)NSString *code;

@end


/*
 GET https://openapi.baidu.com/oauth/2.0/token?
 grant_type=refresh_token&
 refresh_token=Refresh Token的值&
 client_id=您应用的AppKey&
 client_secret=您应用的SecretKey
 }
 */

/*
 The return value is described as follows:
 
 Parameters    Type    Notes
 access_token    string    Access Token, which is the certificate that calls the network disk open API to access user-authorized resources.
 expires_in    int    Access Token is valid in seconds.
 refresh_token    string    Used to refresh Access Token, valid for 10 years.
 scope    string    Access Token's final access, that is, the list of the user's actual authorizations.
 */


@interface PanBaiduNetdiskTokenRefreshRequest : PanBaiduNetdiskAuthRequest

+ (instancetype)requestWithClientID:(NSString *)clientID
                       clientSecret:(NSString *)clientSecret
                          grantType:(NSString *)grantType
                       refreshToken:(NSString *)refreshToken;

@property (nonatomic,copy,readonly)NSString *clientID;
@property (nonatomic,copy,readonly)NSString *clientSecret;
@property (nonatomic,copy,readonly)NSString *grantType;
@property (nonatomic,copy,readonly)NSString *refreshToken;

@end





NS_ASSUME_NONNULL_END
