//
//  CsjBannerAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "CsjBannerAdapter.h"

#if __has_include(<BUAdSDK/BUNativeExpressBannerView.h>)
#import <BUAdSDK/BUNativeExpressBannerView.h>
#else
#import "BUNativeExpressBannerView.h"
#endif

#import "AdServerBidBanner.h"

@interface CsjBannerAdapter () <BUNativeExpressBannerViewDelegate>
@property (nonatomic, strong) BUNativeExpressBannerView *csj_ad;
@property (nonatomic, weak) AdServerBidBanner *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;

@end

@implementation CsjBannerAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
    }
    return self;
}

- (void)loadAd {
    _csj_ad = [[BUNativeExpressBannerView alloc] initWithSlotID:_supplier.sdk_adspot_id rootViewController:_adspot.viewController adSize:_adspot.adContainer.bounds.size interval:_adspot.refreshInterval];
    _csj_ad.frame = _adspot.adContainer.bounds;
    _csj_ad.delegate = self;
    [_adspot.adContainer addSubview:_csj_ad];
    [_csj_ad loadAdData];
}

// MARK: ======================= BUNativeExpressBannerViewDelegate =======================
/**
 *  广告数据拉取成功回调
 *  当接收服务器返回的广告数据成功后调用该函数
 */
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
}

/**
 *  请求广告数据失败后调用
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView didLoadFailWithError:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded  supplier:_supplier error:error];
//    if ([self.delegate respondsToSelector:@selector(adServerBidBannerOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidBannerOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
    [_csj_ad removeFromSuperview];
    _csj_ad = nil;
}

/**
 *  banner2.0曝光回调
 */
- (void)nativeExpressBannerAdViewWillBecomVisible:(BUNativeExpressBannerView *)bannerAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
}

/**
 *  banner2.0点击回调
 */
- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}

/**
 *  banner2.0被用户关闭时调用
 */
- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView dislikeWithReason:(NSArray<BUDislikeWords *> *_Nullable)filterwords {
    [_csj_ad removeFromSuperview];
    _csj_ad = nil;
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

@end
