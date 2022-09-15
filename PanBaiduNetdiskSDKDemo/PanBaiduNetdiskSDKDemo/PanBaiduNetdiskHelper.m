//
//  MyCloudHomeHelper.m
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskHelper.h"
#import "LSOnlineFile.h"
#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>

unsigned long long LSFileContentLengthUnknown = -1;

@implementation PanBaiduNetdiskHelper

+ (LSOnlineFile *)onlineFileForApiItem:(id)item
                       parentDirectory:(LSOnlineFile *)parentDirectory
{
    NSString *rootPath = parentDirectory.url.path;
    NSParameterAssert(item);
    NSParameterAssert(rootPath);
    if(item && rootPath){
        if([item isKindOfClass:[PanBaiduNetdiskFile class]]){
            PanBaiduNetdiskFile *apiFile = (PanBaiduNetdiskFile *)item;
            NSString *title = apiFile.server_filename;
            BOOL isDirectory = [apiFile.isdir boolValue];
            title = [title stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            unsigned long long size = apiFile.size?apiFile.size.unsignedIntegerValue:LSFileContentLengthUnknown;
            NSURL *url = [NSURL fileURLWithPath:[rootPath stringByAppendingPathComponent:title]];
            LSOnlineFile *file = [[LSOnlineFile alloc] init];
            file.url = url;
            file.contentType = [apiFile.category integerValue];
            file.contentLength = size;
            file.createdAt = [[NSDate alloc] initWithTimeIntervalSince1970:apiFile.server_ctime.doubleValue];
            file.updatedAt = [[NSDate alloc] initWithTimeIntervalSince1970:apiFile.server_mtime.doubleValue];
            file.directory = isDirectory;
            file.readOnly = NO;
            file.name = title;
            file.shared = NO;
            file.identifier = apiFile.identifier;
            file.md5 = apiFile.md5;
            return file;
        }
        else if([item isKindOfClass:[LSOnlineFile class]]){
            return item;
        }
    }
    NSParameterAssert(NO);
    return nil;
}

+ (BOOL)shouldFilterApiFile:(id)file {
    return NO;
}

+ (NSArray<LSOnlineFile *> *)onlineFilesFromApiFiles:(id<NSFastEnumeration>)items
                                     parentDirectory:(LSOnlineFile *)parentDirectory{
    NSMutableArray<LSOnlineFile *> *resultFiles = [[NSMutableArray<LSOnlineFile *> alloc] init];
    if(items){
        for (id item in items) {
            if([self shouldFilterApiFile:item]){
                continue;
            }
            LSOnlineFile *onlineFile = nil;
            if([item isKindOfClass:[LSOnlineFile class]]==NO){
                onlineFile = [self onlineFileForApiItem:item parentDirectory:parentDirectory];
            }
            else{
                onlineFile = (LSOnlineFile *)item;
            }
            if(onlineFile){
                [resultFiles addObject:onlineFile];
            }
        }
    }
    return resultFiles;
}

+ (NSString *)uuidString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidStr;
}

+ (NSError *)unknownError{
    return [[NSError alloc] initWithDomain:@"PanBaiduNetdiskAPIClientErrorDomain" code:-1 userInfo:nil];
}

+ (PanBaiduNetdiskAPIClient *)createClientWithAuthData:(NSDictionary *)clientAuthData{
    PanBaiduNetdiskAPIClient *apiClient = nil;
    id accessTokenDataObj = [clientAuthData objectForKey:PanBaiduNetdiskAccessTokenDataKey];
    NSString *userID = [clientAuthData objectForKey:PanBaiduNetdiskUserIDKey];
    if ([accessTokenDataObj isKindOfClass:[NSData class]] && userID.length > 0) {
        NSData *authData = (NSData *)accessTokenDataObj;
        NSParameterAssert(authData.length>0);
        if (authData.length > 0) {
            id obj = [NSKeyedUnarchiver unarchivedObjectOfClass:[PanBaiduNetdiskAccessToken class] fromData:authData error:nil];
            NSParameterAssert([obj isKindOfClass:[PanBaiduNetdiskAccessToken class]]);
            if([obj isKindOfClass:[PanBaiduNetdiskAccessToken class]]){
                PanBaiduNetdiskAuthState *authState = [[PanBaiduNetdiskAuthState alloc] initWithToken:obj];
                apiClient = [[PanBaiduNetdiskAPIClientCache sharedCache] clientForIdentifier:userID];
                if (apiClient == nil) {
                    apiClient = [[PanBaiduNetdiskAPIClientCache sharedCache] createClientForIdentifier:userID
                                                                                             authState:authState
                                                                                  sessionConfiguration:nil];
                }
            }
        }
    }
    else {
        NSParameterAssert(NO);
    }
    NSParameterAssert(apiClient);
    return apiClient;
}

+ (NSString *)readableStringForByteSize:(NSNumber *)size{
    NSString * result_str = nil;
    long long fileSize = [size longLongValue];
    result_str = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
    return result_str;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
