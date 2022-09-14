//
//  LSPreviewItem.h
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 14/09/2022.
//  Copyright © 2022 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>



NS_ASSUME_NONNULL_BEGIN

@interface LSPreviewItem : NSObject <QLPreviewItem>

@property (nonatomic, strong) NSURL *previewItemURL;

@property (nonatomic, strong) NSString *previewItemTitle;

@end

NS_ASSUME_NONNULL_END
