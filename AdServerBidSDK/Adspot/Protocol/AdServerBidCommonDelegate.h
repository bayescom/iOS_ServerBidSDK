//
//  AdServerBidCommonDelegate.h
//  Pods
//
//  Created by MS on 2021/1/16.
//

#ifndef AdServerBidCommonDelegate_h
#define AdServerBidCommonDelegate_h

// 策略相关的代理
@protocol AdServerBidCommonDelegate <NSObject>

@optional

/// 策略请求成功
/// @param reqId 策略id
/// 若 reqId = bottom_default 则执行的是打底渠道
- (void)adServerBidOnAdReceived:(NSString *)reqId;


/// 策略请求失败
/// @param error 聚合SDK的错误
/// @param description 每个渠道的错误详情, 部分情况下为nil  key的命名规则: 渠道名-优先级
- (void)adServerBidFailedWithError:(NSError *)error description:(NSDictionary *)description;

/// 内部渠道开始加载时调用
- (void)adServerBidSupplierWillLoad:(NSString *)supplierId;


//// 开始bidding
//- (void)adServerBidBiddingAction;
//
//// bidding结束
- (void)adServerBidBiddingEndWithPrice:(NSInteger)price;



@end

#endif /* AdServerBidBaseDelegate_h */
