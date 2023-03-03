//
//  AdServerBidSupplierDelegate.h
//  Demo
//
//  Created by CherryKing on 2020/11/25.
//

#ifndef AdServerBidSupplierDelegate_h
#define AdServerBidSupplierDelegate_h

@class AdvSupplierModel;
@class AdvSupplier;
@protocol AdServerBidSupplierDelegate <NSObject>

@optional

/// 加载策略Model成功
- (void)adServerBidBaseAdapterLoadSuccess:(nonnull AdvSupplierModel *)model;

/// 加载策略Model失败
- (void)adServerBidBaseAdapterLoadError:(nullable NSError *)error;


/// 返回下一个渠道的参数
/// @param supplier 被加载的渠道
/// @param error 异常信息
- (void)adServerBidBaseAdapterLoadSuppluer:(nullable AdvSupplier *)supplier error:(nullable NSError *)error;

// 开始bidding
- (void)adServerBidBaseAdapterBiddingAction:(NSMutableArray <AdvSupplier *> *_Nullable)suppliers;

// bidding结束
- (void)adServerBidBaseAdapterBiddingEndWithWinSupplier:(AdvSupplier *_Nonnull)supplier;

@end

#endif /* AdServerBidSupplierDelegate_h */
