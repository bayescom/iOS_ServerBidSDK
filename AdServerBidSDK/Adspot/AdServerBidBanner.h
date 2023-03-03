//
//  AdServerBidBanner.h
//  AdServerBidSDKExample
//
//  Created by CherryKing on 2020/4/7.
//  Copyright © 2020 Mercury. All rights reserved.
//

#import "AdvBaseAdapter.h"
#import "AdvSdkConfig.h"
#import "AdServerBidBannerDelegate.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdServerBidBanner : AdvBaseAdapter
/// 广告方法回调代理
@property (nonatomic, weak) id<AdServerBidBannerDelegate> delegate;

@property(nonatomic, weak) UIView *adContainer;
@property(nonatomic, weak) UIViewController *viewController;
@property(nonatomic, assign) int refreshInterval;

- (instancetype)initWithAdspotId:(NSString *)adspotid
                     adContainer:(UIView *)adContainer
                  viewController:(UIViewController *)viewController;


/// 构造函数
/// @param adspotid adspotid
/// @param adContainer adContainer
/// @param ext 自定义拓展参数
/// @param viewController viewController
- (instancetype)initWithAdspotId:(NSString *)adspotid
                     adContainer:(UIView *)adContainer
                       customExt:(NSDictionary *_Nonnull)ext
                  viewController:(UIViewController *)viewController;


@end

NS_ASSUME_NONNULL_END
