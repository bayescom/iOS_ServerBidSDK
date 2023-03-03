//
//  GdtBannerAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "GdtBannerAdapter.h"

#if __has_include(<GDTUnifiedBannerView.h>)
#import <GDTUnifiedBannerView.h>
#else
#import "GDTUnifiedBannerView.h"
#endif

#import "AdServerBidBanner.h"


@interface GdtBannerAdapter () <GDTUnifiedBannerViewDelegate>
@property (nonatomic, strong) GDTUnifiedBannerView *gdt_ad;
@property (nonatomic, weak) AdServerBidBanner *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;

@end

@implementation GdtBannerAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
    }
    return self;
}

- (void)loadAd {
    
    CGRect rect = CGRectMake(0, 0, _adspot.adContainer.frame.size.width, _adspot.adContainer.frame.size.height);
    _gdt_ad = [[GDTUnifiedBannerView alloc] initWithFrame:rect placementId:_supplier.sdk_adspot_id viewController:_adspot.viewController];
    _gdt_ad.animated = NO;
    _gdt_ad.autoSwitchInterval = _adspot.refreshInterval;
    _gdt_ad.delegate = self;
    [_adspot.adContainer addSubview:_gdt_ad];
    [_gdt_ad loadAdAndShow];
}

// MARK: ======================= GDTUnifiedBannerViewDelegate =======================
/**
 *  广告数据拉取成功回调
 *  当接收服务器返回的广告数据成功后调用该函数
 */
- (void)unifiedBannerViewDidLoad:(GDTUnifiedBannerView *)unifiedBannerView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
}

/**
 *  请求广告数据失败后调用
 *  当接收服务器返回的广告数据失败后调用该函数
 */

- (void)unifiedBannerViewFailedToLoad:(GDTUnifiedBannerView *)unifiedBannerView error:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded  supplier:_supplier error:error];
//    if ([self.delegate respondsToSelector:@selector(adServerBidBannerOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidBannerOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
    [_gdt_ad removeFromSuperview];
    _gdt_ad = nil;
}

/**
 *  banner2.0曝光回调
 */
- (void)unifiedBannerViewWillExpose:(GDTUnifiedBannerView *)unifiedBannerView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
}

/**
 *  banner2.0点击回调
 */
- (void)unifiedBannerViewClicked:(GDTUnifiedBannerView *)unifiedBannerView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}

/**
 *  banner2.0被用户关闭时调用
 */
- (void)unifiedBannerViewWillClose:(GDTUnifiedBannerView *)unifiedBannerView {
    [_gdt_ad removeFromSuperview];
    _gdt_ad = nil;
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

@end
