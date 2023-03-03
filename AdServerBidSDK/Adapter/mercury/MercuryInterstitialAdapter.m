//
//  MercuryInterstitialAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "MercuryInterstitialAdapter.h"
#if __has_include(<MercurySDK/MercuryInterstitialAd.h>)
#import <MercurySDK/MercuryInterstitialAd.h>
#else
#import "MercuryInterstitialAd.h"
#endif

#import "AdServerBidInterstitial.h"
#import "AdvLog.h"

@interface MercuryInterstitialAdapter () <MercuryInterstitialAdDelegate>
@property (nonatomic, strong) MercuryInterstitialAd *mercury_ad;
@property (nonatomic, weak) AdServerBidInterstitial *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;

@end

@implementation MercuryInterstitialAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = (AdServerBidInterstitial *)adspot;
        _supplier = supplier;
        _mercury_ad = [[MercuryInterstitialAd alloc] initAdWithAdspotId:_supplier.sdk_adspot_id delegate:self];
    }
    return self;
}

- (void)deallocAdapter {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    if (_mercury_ad) {
        _mercury_ad.delegate = nil;
        _mercury_ad = nil;
    }
}

- (void)dealloc
{
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [self deallocAdapter];
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载Mercury supplier: %@", _supplier);
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    [_mercury_ad loadAd];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"Mercury加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"Mercury 成功");
    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"Mercury 失败");
    [self.adspot loadNextSupplierIfHas];
}

- (void)loadAd {
    [super loadAd];

}

- (void)showAd {
    [_mercury_ad presentAdFromViewController:_adspot.viewController];
}


// MARK: ======================= MercuryInterstitialAdDelegate =======================
/// 插屏广告预加载成功回调，当接收服务器返回的广告数据成功且预加载后调用该函数
- (void)mercury_interstitialSuccess:(MercuryInterstitialAd *)interstitialAd  {
    _supplier.supplierPrice = interstitialAd.price;
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
    if (_supplier.isParallel == YES) {
//        NSLog(@"修改状态: %@", _supplier);
        _supplier.state = AdServerBidSdkSupplierStateSuccess;
        return;
    }

    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
}

/// 插屏广告预加载失败回调，当接收服务器返回的广告数据失败后调用该函数
- (void)mercury_interstitialFailError:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }
    
    if (_mercury_ad) {
        _mercury_ad = nil;
    }
//    if ([self.delegate respondsToSelector:@selector(adServerBidInterstitialOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidInterstitialOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
}

/// 插屏广告视图曝光失败回调，插屏广告曝光失败回调该函数
- (void)mercury_interstitialFailToPresent:(MercuryInterstitialAd *)interstitialAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:[NSError errorWithDomain:@"广告素材渲染失败" code:301 userInfo:@{@"msg": @"广告素材渲染失败"}]];
    if (_mercury_ad) {
        _mercury_ad = nil;
    }

//    if ([self.delegate respondsToSelector:@selector(adServerBidInterstitialOnAdRenderFailed)]) {
//        [self.delegate adServerBidInterstitialOnAdRenderFailed];
//    }
    
}

/// 插屏广告曝光回调
- (void)mercury_interstitialWillExposure:(MercuryInterstitialAd *)interstitialAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
}

/// 插屏广告点击回调
- (void)mercury_interstitialClicked:(MercuryInterstitialAd *)interstitialAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}

/// 插屏广告曝光结束回调，插屏广告曝光结束回调该函数
- (void)mercury_interstitialDidDismissScreen:(MercuryInterstitialAd *)interstitialAd {
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

@end
