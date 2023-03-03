//
//  GdtInterstitialAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "GdtInterstitialAdapter.h"

#if __has_include(<GDTUnifiedInterstitialAd.h>)
#import <GDTUnifiedInterstitialAd.h>
#else
#import "GDTUnifiedInterstitialAd.h"
#endif

#import "AdServerBidInterstitial.h"
#import "AdvLog.h"

@interface GdtInterstitialAdapter () <GDTUnifiedInterstitialAdDelegate>
@property (nonatomic, strong) GDTUnifiedInterstitialAd *gdt_ad;
@property (nonatomic, weak) AdServerBidInterstitial *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, assign) BOOL isCanch;

@end

@implementation GdtInterstitialAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = (AdServerBidInterstitial *)adspot;
        _supplier = supplier;
        _gdt_ad = [[GDTUnifiedInterstitialAd alloc] initWithPlacementId:_supplier.sdk_adspot_id];
    }
    return self;
}


- (void)loadAd {
    ADV_LEVEL_INFO_LOG(@"加载广点通 supplier: %@", _supplier);
    [super loadAd];
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"广点通 load ad");
    _gdt_ad.delegate = self;
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    [_gdt_ad loadAd];

}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"广点通 正在加载中");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"广点通 成功");
    
    [self unifiedDelegate];
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"广点通 失败 %@", _supplier);
    [self deallocAdapter];
    [self.adspot loadNextSupplierIfHas];
}




- (void)showAd {
    [_gdt_ad presentAdFromRootViewController:_adspot.viewController];
}

- (void)deallocAdapter {
    if (_gdt_ad) {
        _gdt_ad.delegate = nil;
        _gdt_ad = nil;
    }
}



- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [self deallocAdapter];
}


// MARK: ======================= GdtInterstitialAdDelegate =======================
/// 插屏广告预加载成功回调，当接收服务器返回的广告数据成功且预加载后调用该函数
- (void)unifiedInterstitialSuccessToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    
}

- (void)unifiedInterstitialRenderSuccess:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    _supplier.supplierPrice = unifiedInterstitial.eCPM;
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
//    NSLog(@"广点通插屏拉取成功 %@",self.gdt_ad);
    if (_supplier.isParallel == YES) {
//        NSLog(@"修改状态: %@", _supplier);
        _supplier.state = AdServerBidSdkSupplierStateSuccess;
        return;
    }
    
    [self unifiedDelegate];


}

/// 插屏广告预加载失败回调，当接收服务器返回的广告数据失败后调用该函数
- (void)unifiedInterstitialFailToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded  supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }
    
    [self deallocAdapter];
//    if ([self.delegate respondsToSelector:@selector(adServerBidInterstitialOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidInterstitialOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
}

/// 插屏广告曝光回调
- (void)unifiedInterstitialWillExposure:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
}

/// 插屏广告点击回调
- (void)unifiedInterstitialClicked:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}

/// 插屏广告曝光结束回调，插屏广告曝光结束回调该函数
- (void)unifiedInterstitialDidDismissScreen:(id)unifiedInterstitial {
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

- (void)unifiedDelegate {
    if (_isCanch) {
        return;
    }
    _isCanch = YES;
    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
}


@end
