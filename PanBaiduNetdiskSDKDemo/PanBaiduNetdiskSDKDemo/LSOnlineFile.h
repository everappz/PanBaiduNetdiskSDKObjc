//
//  LSOnlineFile.h
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LSOnlineFile : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) unsigned long long contentLength;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, assign) BOOL directory;
@property (nonatomic, assign) BOOL readOnly;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL shared;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *md5;

@end

NS_ASSUME_NONNULL_END
