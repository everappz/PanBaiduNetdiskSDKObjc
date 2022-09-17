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

extern unsigned long long LSFileContentLengthUnknown;

@interface DemoHelper : NSObject

+ (LSOnlineFile *)onlineFileForApiItem:(id)item
                       parentDirectory:(LSOnlineFile *)parentDirectory;

+ (NSArray<LSOnlineFile *> *)onlineFilesFromApiFiles:(id<NSFastEnumeration>)items
                                     parentDirectory:(LSOnlineFile *)parentDirectory;

+ (NSString *)uuidString;

+ (NSError *)unknownError;

+ (NSString *)readableStringForByteSize:(NSNumber *)size;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
