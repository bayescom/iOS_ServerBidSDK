//
//  GdtSplashAdapter.m
//  AdServerBidSDKExample
//
//  Created by CherryKing on 2020/4/8.
//  Copyright © 2020 Gdt. All rights reserved.
//

#import "GdtSplashAdapter.h"

#if __has_include(<GDTSplashAd.h>)
#import <GDTSplashAd.h>
#else
#import "GDTSplashAd.h"
#endif

#if __has_include(<GDTSDKConfig.h>)
#import <GDTSDKConfig.h>
#else
#import "GDTSDKConfig.h"
#endif


#import "AdServerBidSplash.h"
#import "UIApplication+Adv.h"
#import "AdvLog.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface GdtSplashAdapter () <GDTSplashAdDelegate>
@property (nonatomic, strong) GDTSplashAd *gdt_ad;
@property (nonatomic, weak) AdServerBidSplash *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;

// 剩余时间，用来判断用户是点击跳过，还是正常倒计时结束
@property (nonatomic, assign) NSUInteger leftTime;
// 是否点击了
@property (nonatomic, assign) BOOL isClick;
@property (nonatomic, assign) BOOL isCanch;

@end

@implementation GdtSplashAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        _leftTime = 5;  // 默认5s
    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载广点通 supplier: %@", _supplier);
    _gdt_ad = [[GDTSplashAd alloc] initWithPlacementId:_supplier.sdk_adspot_id token:_supplier.winSupplierInfo];
    _gdt_ad.delegate = self;
    if (!_gdt_ad) {
        return;
    }
    _adspot.viewController.modalPresentationStyle = 0;
    // 设置 backgroundImage
    _gdt_ad.backgroundImage = _adspot.backgroundImage;
    
    NSInteger parallel_timeout = _supplier.timeout;
    if (parallel_timeout == 0) {
        parallel_timeout = 3000;
    }
    _gdt_ad.fetchDelay = parallel_timeout / 1000.0;
    
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    [_gdt_ad loadAd];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"广点通加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"广点通 成功");
    [self unifiedDelegate];
}

- (void)supplierRequestToken {
    ADV_LEVEL_INFO_LOG(@"广点通 请求buyer_id和sdk_info");
    NSString *buyerId = [GDTSDKConfig getBuyerIdWithContext:nil];
    NSString *sdkInfo = [GDTSDKConfig getSDKInfoWithPlacementId:_supplier.sdk_adspot_id];

    _supplier.buyerId = buyerId;
    _supplier.sdkInfo = sdkInfo;
    _supplier.state = AdServerBidSdkSupplierStateInPull;

    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBiddingToken supplier:_supplier error:nil];
//    NSLog(@"广点通buyerId: %@\r\n广点通sdkInfo: %@", buyerId, sdkInfo);

}


- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"广点通 失败");
    [self.adspot loadNextSupplierIfHas];
    [self deallocAdapter];
}


- (void)loadAd {
    [super loadAd];
}

// MARK: ======================= GDTSplashAdDelegate =======================
- (void)splashAdSuccessPresentScreen:(GDTSplashAd *)splashAd {
}

- (void)deallocAdapter {
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    if (_gdt_ad) {
        _gdt_ad.delegate = nil;
        _gdt_ad = nil;
    }
}

- (void)showAd {
    [self showAdAction];
}
- (void)showAdAction {
    // 设置logo
    UIImageView *imgV;
    if (_adspot.logoImage) {
        CGFloat real_w = [UIScreen mainScreen].bounds.size.width;
        CGFloat real_h = _adspot.logoImage.size.height*(real_w/_adspot.logoImage.size.width);
        imgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, real_w, real_h)];
        imgV.userInteractionEnabled = YES;
        imgV.image = _adspot.logoImage;
    }
    if (self.gdt_ad) {
        
        if ([self.gdt_ad isAdValid]) {
            [_gdt_ad showAdInWindow:[UIApplication sharedApplication].adv_getCurrentWindow withBottomView:_adspot.showLogoRequire?imgV:nil skipView:nil];
        } else {
            
        }
    }
}

- (void)splashAdDidLoad:(GDTSplashAd *)splashAd {
//    NSLog(@"广点通开屏拉取成功 %@ %d",self.gdt_ad ,[self.gdt_ad isAdValid]);
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
//    NSLog(@"广点通开屏拉取成功 %d",splashAd.eCPM);

    if (_supplier.isParallel == YES) {
//        NSLog(@"修改状态: %@", _supplier);
        _supplier.state = AdServerBidSdkSupplierStateSuccess;
        return;
    }
    [self unifiedDelegate];
}

- (void)splashAdExposured:(GDTSplashAd *)splashAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(adServerBidExposured)] && self.gdt_ad) {
        [self.delegate adServerBidExposured];
    }
}

- (void)splashAdFailToPresent:(GDTSplashAd *)splashAd withError:(NSError *)error {
    
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }

//    if ([self.delegate respondsToSelector:@selector(adServerBidSplashOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidSplashOnAdFailedWithSdkId:_adspot.adspotid error:error];
//    }
}

- (void)splashAdClicked:(GDTSplashAd *)splashAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
    _isClick = YES;
}

- (void)splashAdClosed:(GDTSplashAd *)splashAd {
    // 如果时间大于0 且不是因为点击触发的，则认为是点击了跳过
    if (_leftTime > 0 && !_isClick) {
        if ([self.delegate respondsToSelector:@selector(adServerBidSplashOnAdSkipClicked)]) {
            [self.delegate adServerBidSplashOnAdSkipClicked];
        }
        if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
            [self.delegate adServerBidDidClose];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
            [self.delegate adServerBidDidClose];
        }
    }
}

- (void)splashAdLifeTime:(NSUInteger)time {
    _leftTime = time;
//    if (time <= 0 && [self.delegate respondsToSelector:@selector(adServerBidSplashOnAdCountdownToZero)]) {
//        [self.delegate adServerBidSplashOnAdCountdownToZero];
//    }
    
    if (time <= 0 && [self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
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
    [self showAd];
}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    [self deallocAdapter];

}
@end
