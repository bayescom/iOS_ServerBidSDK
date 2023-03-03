//
//  AdServerBidNativeExpressProtocol.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#ifndef AdServerBidNativeExpressProtocol_h
#define AdServerBidNativeExpressProtocol_h
#import "AdServerBidCommonDelegate.h"
@class AdServerBidNativeExpressView;
@protocol AdServerBidNativeExpressDelegate <AdServerBidCommonDelegate>
@optional
/// 广告数据拉取成功
- (void)adServerBidNativeExpressOnAdLoadSuccess:(nullable NSArray<AdServerBidNativeExpressView *> *)views;

/// 广告曝光
- (void)adServerBidNativeExpressOnAdShow:(nullable AdServerBidNativeExpressView *)adView;

/// 广告点击
- (void)adServerBidNativeExpressOnAdClicked:(nullable AdServerBidNativeExpressView *)adView;

/// 广告渲染成功
- (void)adServerBidNativeExpressOnAdRenderSuccess:(nullable AdServerBidNativeExpressView *)adView;

/// 广告渲染失败
- (void)adServerBidNativeExpressOnAdRenderFail:(nullable AdServerBidNativeExpressView *)adView;

/// 广告被关闭 (注: 百度广告(百青藤), 不支持该回调, 若使用百青藤,则该回到功能请自行实现)
- (void)adServerBidNativeExpressOnAdClosed:(nullable AdServerBidNativeExpressView *)adView;

@end

#endif
