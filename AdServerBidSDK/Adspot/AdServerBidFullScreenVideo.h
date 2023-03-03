//
//  AdServerBidFullScreenVideo.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/13.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "AdvBaseAdapter.h"

#import <UIKit/UIKit.h>

#import "AdvSdkConfig.h"
#import "AdServerBidFullScreenVideoDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdServerBidFullScreenVideo : AdvBaseAdapter
/// 广告方法回调代理
@property (nonatomic, weak) id<AdServerBidFullScreenVideoDelegate> delegate;

@property (nonatomic, weak) UIViewController *viewController;

- (instancetype)initWithAdspotId:(NSString *)adspotid
                  viewController:(UIViewController *)viewController;


/// 构造函数
/// @param adspotid adspotid
/// @param ext 自定义拓展参数
/// @param viewController viewController
- (instancetype)initWithAdspotId:(NSString *)adspotid
                       customExt:(NSDictionary *_Nonnull)ext
                  viewController:(UIViewController *)viewController;

- (void)showAd;
@end

NS_ASSUME_NONNULL_END
