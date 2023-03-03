//
//  CsjFullScreenVideoAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/13.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "CsjFullScreenVideoAdapter.h"
#if __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#else
#import "BUAdSDK.h"
#endif
#import "AdServerBidFullScreenVideo.h"
#import "AdvLog.h"

@interface CsjFullScreenVideoAdapter () <BUNativeExpressFullscreenVideoAdDelegate>
@property (nonatomic, strong) BUNativeExpressFullscreenVideoAd *csj_ad;
@property (nonatomic, weak) AdServerBidFullScreenVideo *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, assign) BOOL isCached;

@end

@implementation CsjFullScreenVideoAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        
        _csj_ad = [[BUNativeExpressFullscreenVideoAd alloc] initWithSlotID:_supplier.sdk_adspot_id];
    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载穿山甲 supplier: %@", _supplier);
    _csj_ad.delegate = self;
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    [self.csj_ad loadAdData];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"穿山甲加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"穿山甲 成功");
    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
    if (_isCached) {
        if ([self.delegate respondsToSelector:@selector(adServerBidFullScreenVideoOnAdVideoCached)]) {
            [self.delegate adServerBidFullScreenVideoOnAdVideoCached];
        }
    }
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"穿山甲 失败");
    [self.adspot loadNextSupplierIfHas];
}


- (void)loadAd {
    [super loadAd];
}

- (void)showAd {
    [_csj_ad showAdFromRootViewController:_adspot.viewController];
}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
}


// MARK: ======================= BUNativeExpressFullscreenVideoAdDelegate =======================
/// 广告预加载成功回调
- (void)nativeExpressFullscreenVideoAdDidLoad:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded  supplier:_supplier error:nil];
//    NSLog(@"穿山甲全屏视频拉取成功");
    _supplier.state = AdServerBidSdkSupplierStateSuccess;
    if (_supplier.isParallel == YES) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
}

- (void)nativeExpressFullscreenVideoAdDidDownLoadVideo:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if (_supplier.isParallel == YES) { // 并行不释放 只上报
        _isCached = YES;
        return;
    }
    if ([self.delegate respondsToSelector:@selector(adServerBidFullScreenVideoOnAdVideoCached)]) {
        [self.delegate adServerBidFullScreenVideoOnAdVideoCached];
    }
}

/// 广告预加载失败回调
- (void)nativeExpressFullscreenVideoAd:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) { // 并行不释放 只上报
        return;
    }
    _csj_ad = nil;
//    if ([self.delegate respondsToSelector:@selector(adServerBidFullScreenVideoOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidFullScreenVideoOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
}

/// 渲染失败
- (void)nativeExpressFullscreenVideoAdViewRenderFail:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd error:(NSError *_Nullable)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _csj_ad = nil;
//    if ([self.delegate respondsToSelector:@selector(adServerBidFullScreenVideoOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidFullScreenVideoOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
}

/// 广告曝光回调
- (void)nativeExpressFullscreenVideoAdDidVisible:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
}

/// 广告点击回调
- (void)nativeExpressFullscreenVideoAdDidClick:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}

/// 广告曝光结束回调
- (void)nativeExpressFullscreenVideoAdDidClose:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

/// 广告播放结束
- (void)nativeExpressFullscreenVideoAdDidPlayFinish:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    if (!error) {
        if ([self.delegate respondsToSelector:@selector(adServerBidFullScreenVideoOnAdPlayFinish)]) {
            [self.delegate adServerBidFullScreenVideoOnAdPlayFinish];
        }
    }
}

// 点击了跳过
- (void)nativeExpressFullscreenVideoAdDidClickSkip:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if ([self.delegate respondsToSelector:@selector(adServerBidFullScreenVideodDidClickSkip)]) {
        [self.delegate adServerBidFullScreenVideodDidClickSkip];
    }
}



- (void)nativeExpressFullscreenVideoAdViewRenderSuccess:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd {
    
}


@end
