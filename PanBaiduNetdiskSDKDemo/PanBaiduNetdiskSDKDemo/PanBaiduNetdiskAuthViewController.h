//
//  MyCloudHomeAuthViewController.h
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PanBaiduNetdiskAuthViewController;

@protocol PanBaiduNetdiskAuthViewControllerDelegate <NSObject>

- (void)panBaiduNetdiskAuthViewController:(PanBaiduNetdiskAuthViewController *)viewController didFailWithError:(NSError *)error;

- (void)panBaiduNetdiskAuthViewController:(PanBaiduNetdiskAuthViewController *)viewController didSuccessWithAuth:(NSDictionary *)auth;

@end


@interface PanBaiduNetdiskAuthViewController : UIViewController

- (void)start;

@property (nonatomic,weak)id<PanBaiduNetdiskAuthViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
