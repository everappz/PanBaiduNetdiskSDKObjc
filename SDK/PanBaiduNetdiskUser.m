//
//  PanBaiduNetdiskUser.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskUser.h"

@implementation PanBaiduNetdiskUser

- (NSString * _Nullable)baiduName{
    return [self.class stringForKey:@"baidu_name" inDictionary:self.dictionary];
}

- (NSString * _Nullable)netdiskName{
    return [self.class stringForKey:@"netdisk_name" inDictionary:self.dictionary];
}

- (NSString * _Nullable)avatarUrl{
    return [self.class stringForKey:@"avatar_url" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)vipType{
    return [self.class numberForKey:@"vip_type" inDictionary:self.dictionary];
}

- (NSString * _Nullable)userID{
    return [self.class stringForKey:@"uk" inDictionary:self.dictionary];
}

@end
