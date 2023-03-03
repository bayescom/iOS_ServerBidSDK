//
//  MercuryBannerAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "MercuryBannerAdapter.h"

#if __has_include(<MercurySDK/MercuryBannerAdView.h>)
#import <MercurySDK/MercuryBannerAdView.h>
#else
#import "MercuryBannerAdView.h"
#endif

#import "AdServerBidBanner.h"
#import "AdvLog.h"

@interface MercuryBannerAdapter () <MercuryBannerAdViewDelegate>
@property (nonatomic, strong) MercuryBannerAdView *mercury_ad;
@property (nonatomic, weak) AdServerBidBanner *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;

@end

@implementation MercuryBannerAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
    }
    return self;
}

- (void)loadAd {
    CGRect rect = CGRectMake(0, 0, _adspot.adContainer.frame.size.width, _adspot.adContainer.frame.size.height);
    _mercury_ad = [[MercuryBannerAdView alloc] initWithFrame:rect adspotId:_supplier.sdk_adspot_id delegate:self];
    _mercury_ad.controller = _adspot.viewController;
    _mercury_ad.animationOn = YES;
    _mercury_ad.showCloseBtn = YES;
    _mercury_ad.interval = _adspot.refreshInterval;
    [_adspot.adContainer addSubview:_mercury_ad];
    [_mercury_ad loadAdAndShow];
}

- (void)dealloc {
    ADVLog(@"%s", __func__);
}

// MARK: ======================= MercuryBannerAdViewDelegate =======================
// 广告数据拉取成功回调
- (void)mercury_bannerViewDidReceived {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
}

// 请求广告数据失败后调用
- (void)mercury_bannerViewFailToReceived:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded  supplier:_supplier error:error];
    [_mercury_ad removeFromSuperview];
    _mercury_ad = nil;
//    if ([self.delegate respondsToSelector:@selector(adServerBidBannerOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidBannerOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
}

// 曝光回调
- (void)mercury_bannerViewWillExposure {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
}

// 点击回调
- (void)mercury_bannerViewClicked {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}

// 关闭回调
- (void)mercury_bannerViewWillClose {
    [_mercury_ad removeFromSuperview];
    _mercury_ad = nil;
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

@end
