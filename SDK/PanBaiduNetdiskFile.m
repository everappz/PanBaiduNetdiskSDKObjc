//
//  PanBaiduNetdiskFile.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskFile.h"

@implementation PanBaiduNetdiskFile

- (NSString *)identifier{
    return [self.class stringForKey:@"fs_id" inDictionary:self.dictionary];
}

- (NSString * _Nullable)path{
    return [self.class stringForKey:@"path" inDictionary:self.dictionary];
}

- (NSString * _Nullable)server_filename{
    return [self.class stringForKey:@"server_filename" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)size{
    return [self.class numberForKey:@"size" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)server_mtime{
    return [self.class numberForKey:@"server_mtime" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)server_ctime{
    return [self.class numberForKey:@"server_ctime" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)local_mtime{
    return [self.class numberForKey:@"local_mtime" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)local_ctime{
    return [self.class numberForKey:@"local_ctime" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)isdir{
    return [self.class numberForKey:@"isdir" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)category{
    return [self.class numberForKey:@"category" inDictionary:self.dictionary];
}

- (NSString * _Nullable)md5{
    return [self.class stringForKey:@"md5" inDictionary:self.dictionary];
}

- (NSNumber * _Nullable)dir_empty{
    return [self.class numberForKey:@"dir_empty" inDictionary:self.dictionary];
}

- (NSArray * _Nullable)thumbs{
    return [self.class arrayForKey:@"thumbs" inDictionary:self.dictionary];
}

@end



