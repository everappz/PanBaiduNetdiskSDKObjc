//
//  PanBaiduNetdiskUser.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2023 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskObject.h"

NS_ASSUME_NONNULL_BEGIN


@interface PanBaiduNetdiskUser : PanBaiduNetdiskObject

- (NSString * _Nullable)baiduName;

- (NSString * _Nullable)netdiskName;

- (NSString * _Nullable)avatarUrl;

- (NSNumber * _Nullable)vipType;

- (NSString * _Nullable)userID;

@end

NS_ASSUME_NONNULL_END
