//
//  AdvSupplierModel.h
//  Demo
//
//  Created by CherryKing on 2020/11/18.
//

#import <Foundation/Foundation.h>

@class AdvSupplierModel;
@class AdvSupplier;
@class AdvSupplierAdspot;
typedef NS_ENUM(NSUInteger, AdServerBidSdkSupplierRepoType) {
    /// 发起加载请求上报
    AdServerBidSdkSupplierRepoLoaded,
    /// 点击上报
    AdServerBidSdkSupplierRepoClicked,
    /// 数据加载成功上报
    AdServerBidSdkSupplierRepoSucceeded,
    /// 曝光上报
    AdServerBidSdkSupplierRepoImped,
    /// 失败上报
    AdServerBidSdkSupplierRepoFaileded,
    /// bidding结果上报
    AdServerBidSdkSupplierRepoBidding,
    /// bidding广告位生命周期上报
    AdServerBidSdkSupplierRepoGMBidding,
    /// bidding广告位 上报token相关的信息
    AdServerBidSdkSupplierRepoBiddingToken,
    /// bidding广告位 上报胜出渠道的相关的信息
    AdServerBidSdkSupplierRepoBiddingWinInfo

};

typedef NS_ENUM(NSUInteger, AdServerBidSdkSupplierState) {
    /// 未知
    AdServerBidSdkSupplierStateUnknown,
    /// 准备就绪
    AdServerBidSdkSupplierStateReady,
    /// 渠道请求成功(只是请求成功 不是曝光成功)
    AdServerBidSdkSupplierStateSuccess,
    /// 渠道请求失败
    AdServerBidSdkSupplierStateFailed,
    /// 渠道进行中(广告发起请求前)
    AdServerBidSdkSupplierStateInHand,
    
    /// 广告请求进行中(广告发起请求后到结果确定前)
    AdServerBidSdkSupplierStateInPull,

};

NS_ASSUME_NONNULL_BEGIN

NSString * ADVStringFromNAdServerBidSdkSupplierRepoType(AdServerBidSdkSupplierRepoType type);

#pragma mark - Object interfaces

@interface AdvSupplierModel : NSObject
@property (nonatomic, strong)   NSMutableArray<AdvSupplier *> *suppliers;
@property (nonatomic, strong)   AdvSupplierAdspot *adspot;// Mercury 信息
@property (nonatomic, copy)   NSString *msg;
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy)   NSString *reqid;

@property (nonatomic, copy)   NSString *advMediaId;
@property (nonatomic, copy)   NSString *advAdspotId;


@end

@interface AdvSupplierAdspot : NSObject

@property (nonatomic, copy)   NSString *appid;
@property (nonatomic, copy)   NSString *adspotid;
@property (nonatomic, copy)   NSString *appkey;

@end


@interface AdvSupplier : NSObject
@property (nonatomic, copy)   NSString *sdk_app_id;
@property (nonatomic, copy)   NSString *adspot_channel;
@property (nonatomic, copy)   NSString *sdk_id;
@property (nonatomic, copy)   NSString *sdk_adspot_id;
@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, assign) NSInteger timeout;

// token相关
// GDT
@property (nonatomic, copy) NSString *buyerId;
@property (nonatomic, copy) NSString *sdkInfo;
// CSJ
@property (nonatomic, copy) NSString *token;
// KS
@property (nonatomic, copy) NSString *ksToken;
// 各个渠道token  这个字段只在 MercuryAdapter里有用
@property (nonatomic, strong) NSMutableArray *sdkBiddingInfo;

@property (nonatomic, copy) NSString *winSupplierId; // 胜出的渠道id
@property (nonatomic, copy) NSString *winSupplierInfo; // 胜出的渠道信息adm token bidResponse

@property (nonatomic, assign) BOOL isParallel;// 是否并行
@property (nonatomic, assign) AdServerBidSdkSupplierState state;// 渠道状态


@end


NS_ASSUME_NONNULL_END
