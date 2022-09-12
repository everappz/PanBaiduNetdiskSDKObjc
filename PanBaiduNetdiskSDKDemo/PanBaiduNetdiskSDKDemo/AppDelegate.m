//
//  AppDelegate.m
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "AppDelegate.h"
#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>

#define PAN_BAIDU_NET_DISK_CLIENT_ID                                   @"fs8iRdRa98T1GPG9YNXFBDMzXYkAFuzB"
#define PAN_BAIDU_NET_DISK_CLIENT_SECRET                               @"0sKYFhi3ahvMXX0Or9K8DnnIewfw1Tua"
#define PAN_BAIDU_NET_DISK_CALLBACK_URL                                @"pan-baidu-app-27353164://auth_success"
#define PAN_BAIDU_NET_DISK_APP_ID                                      @"27353164"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSParameterAssert(PAN_BAIDU_NET_DISK_CLIENT_ID.length > 0);
    NSParameterAssert(PAN_BAIDU_NET_DISK_CLIENT_SECRET.length > 0);
    NSParameterAssert(PAN_BAIDU_NET_DISK_APP_ID.length > 0);
    NSParameterAssert(PAN_BAIDU_NET_DISK_CALLBACK_URL.length > 0);
    
    [PanBaiduAppAuthManager setSharedManagerWithClientID:PAN_BAIDU_NET_DISK_CLIENT_ID
                                            clientSecret:PAN_BAIDU_NET_DISK_CLIENT_SECRET
                                                   appID:PAN_BAIDU_NET_DISK_APP_ID
                                             redirectURI:PAN_BAIDU_NET_DISK_CALLBACK_URL];

    return YES;
}


#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

@end
