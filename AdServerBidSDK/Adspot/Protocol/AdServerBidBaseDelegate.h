//
//  AdServerBidBaseDelegate.h
//  Pods
//
//  Created by MS on 2020/12/9.
//

#ifndef AdServerBidBaseDelegate_h
#define AdServerBidBaseDelegate_h
#import "AdServerBidCommonDelegate.h"
// 策略相关的代理
@protocol AdServerBidBaseDelegate <AdServerBidCommonDelegate>

@optional

/// 广告曝光成功
- (void)adServerBidExposured;

/// 广告点击回调
- (void)adServerBidClicked;

/// 广告数据请求成功后调用
- (void)adServerBidUnifiedViewDidLoad;

/// 广告关闭的回调
- (void)adServerBidDidClose;

@end

#endif /* AdServerBidBaseDelegate_h */
