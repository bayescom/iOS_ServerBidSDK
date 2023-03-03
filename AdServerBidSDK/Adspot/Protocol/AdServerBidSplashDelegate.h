//
//  AdServerBidSplashProtocol.h
//  AdServerBidSDKExample
//
//  Created by CherryKing on 2020/4/8.
//  Copyright © 2020 Mercury. All rights reserved.
//

#ifndef AdServerBidSplashProtocol_h
#define AdServerBidSplashProtocol_h
#import "AdServerBidBaseDelegate.h"
@protocol AdServerBidSplashDelegate <AdServerBidBaseDelegate>
@optional
/// 广告点击跳过
#pragma 百度广告不支持该回调
- (void)adServerBidSplashOnAdSkipClicked DEPRECATED_MSG_ATTRIBUTE("该回调在使用AdvBidding功能时 不执行, 请在 -adServerBidDidClose 中处理关闭时的相关业务");

/// 广告倒计时结束回调 百度广告不支持该回调
#pragma 百度广告不支持该回调
- (void)adServerBidSplashOnAdCountdownToZero DEPRECATED_MSG_ATTRIBUTE("该回调即将被废弃, 请在 -adServerBidDidClose 中处理相关闭时关业务");;


@end

#endif 
