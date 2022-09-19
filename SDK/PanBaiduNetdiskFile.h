//
//  PanBaiduNetdiskFile.h
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskObject.h"

NS_ASSUME_NONNULL_BEGIN

/*
Response parameters
Parameter name    Type    Description
 
fs_id    uint64    The unique identification ID of the file in the cloud
path    string    Absolute path of the file
filename    string    File name
size    uint    File size, unit B
server_mtime    uint    File modification time on the server
server_ctime    uint    The time when the file was created on the server
local_mtime    uint    The file is modified on the client side.
local_ctime    uint    File creation time on client
isdir    uint    Whether it is a directory, 0 file, 1 directory
Category    uint    File Type, 1 Video, 2 Audio, 3 Pictures, 4 Documents, 5 Apps, 6 Other, 7 Seeds
md5    string    Cloud hash (non-file real MD5), this field only exists when it is a file type.
dir_empty    int    Is there a subdirectory in the directory? Only when the request parameter web=1 and the entry is a directory will the field exist, 0 exists, and 1 is non-existent.
thumbs    array    This field only exists when the parameter web=1 is requested and the entry is classified as a picture, containing a three-size thumbnail URL.
*/

@interface PanBaiduNetdiskFile : PanBaiduNetdiskObject

- (NSString * _Nullable)identifier;

- (NSString * _Nullable)path;

- (NSString * _Nullable)name;

- (NSNumber * _Nullable)size;

- (NSNumber * _Nullable)server_mtime;

- (NSNumber * _Nullable)server_ctime;

- (NSNumber * _Nullable)local_mtime;

- (NSNumber * _Nullable)local_ctime;

- (NSNumber * _Nullable)isdir;

- (NSNumber * _Nullable)category;

- (NSString * _Nullable)md5;

- (NSNumber * _Nullable)dir_empty;

- (NSNumber * _Nullable)share;

- (NSArray * _Nullable)thumbs;

- (NSNumber * _Nullable)duration;

- (NSString * _Nullable)dlink;

@end

NS_ASSUME_NONNULL_END
