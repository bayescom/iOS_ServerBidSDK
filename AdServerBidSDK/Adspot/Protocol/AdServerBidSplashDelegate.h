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
- (void)adServerBidSplashOnAdSkipClicked;

/// 广告倒计时结束回调
//- (void)adServerBidSplashOnAdCountdownToZero  DEPRECATED_MSG_ATTRIBUTE("该方法已废弃");;


@end

#endif 
