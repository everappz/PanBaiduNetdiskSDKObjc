//
//  MyCloudHomeHelper.h
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LSOnlineFile;
@class PanBaiduNetdiskAPIClient;

#define LS_WEB_VIEW_SCALE_TO_FIT_SCRIPT() @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"

extern unsigned long long LSFileContentLengthUnknown;

@interface PanBaiduNetdiskHelper : NSObject

+ (LSOnlineFile *)onlineFileForApiItem:(id)item
                       parentDirectory:(LSOnlineFile *)parentDirectory;

+ (NSArray<LSOnlineFile *> *)onlineFilesFromApiFiles:(id<NSFastEnumeration>)items
                                     parentDirectory:(LSOnlineFile *)parentDirectory;

+ (NSString *)uuidString;

+ (NSError *)unknownError;

+ (PanBaiduNetdiskAPIClient *)createClientWithAuthData:(NSDictionary *)authData;

+ (NSString *)readableStringForByteSize:(NSNumber *)size;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
