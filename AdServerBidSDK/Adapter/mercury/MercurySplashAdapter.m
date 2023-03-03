//
//  MercurySplashAdapter.m
//  AdServerBidSDKExample
//
//  Created by CherryKing on 2020/4/8.
//  Copyright © 2020 Mercury. All rights reserved.
//

#import "MercurySplashAdapter.h"

#if __has_include(<MercurySDK/MercurySplashAd.h>)
#import <MercurySDK/MercurySplashAd.h>
#else
#import "MercurySplashAd.h"
#endif

#import "AdvSupplierModel.h"
#import "AdServerBidSplash.h"
#import "AdvLog.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <MercurySDK/MercurySDK.h>
@interface MercurySplashAdapter () <MercurySplashAdDelegate>
@property (nonatomic, strong) MercurySplashAd *mercury_ad;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, weak) AdServerBidSplash *adspot;
@property (nonatomic, assign) BOOL isCanch;
@property (nonatomic, assign) NSInteger isGMBidding;

@end

@implementation MercurySplashAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        [MercuryConfigManager openDebug:YES];
        _mercury_ad = [[MercurySplashAd alloc] initAdWithAdspotId:_supplier.sdk_adspot_id delegate:self];
        _mercury_ad.placeholderImage = _adspot.backgroundImage;
        _mercury_ad.logoImage = _adspot.logoImage;
        NSNumber *showLogoType = _adspot.extParameter[MercuryLogoShowTypeKey];
        NSNumber *blankGap = _adspot.extParameter[MercuryLogoShowBlankGapKey];

        
        if (showLogoType) {
            _mercury_ad.showType = (showLogoType.integerValue);
        } else {
            _mercury_ad.showType = MercurySplashAdAutoAdaptScreenWithLogoFirst;
        }

        _mercury_ad.blankGap = blankGap.integerValue;
        _mercury_ad.delegate = self;
        _mercury_ad.controller = _adspot.viewController;
    }
    return self;
}



- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载Mercury supplier: %@", _supplier);
    //        if (_adspot.showLogoRequire) {
    //            _mercury_ad.showType = MercurySplashAdAutoAdaptScreen;
    //        }
    if (_adspot.timeout) {
        if (_adspot.timeout > 500) {
            _mercury_ad.fetchDelay = _supplier.timeout / 1000.0;
        }
    }
    
    [_mercury_ad loadAd];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"Mercury加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"Mercury 成功");
    [self unifiedDelegate];
    
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"Mercury 失败");
    [self.adspot loadNextSupplierIfHas];
    [self deallocAdapter];
}


- (void)loadAd {
    [super loadAd];
}


- (void)gmShowAd {
    [self showAdAction];
}

- (void)showAd {
    NSNumber *isGMBidding = ((NSNumber * (*)(id, SEL))objc_msgSend)((id)self.adspot, @selector(isGMBidding));
    self.isGMBidding = isGMBidding.integerValue;

    if (isGMBidding.integerValue == 1) {
        return;
    }
    [self showAdAction];
}

- (void)showAdAction {
//    [[UIApplication sharedApplication].keyWindow addSubview:_csj_ad];
//    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:[_adspot performSelector:@selector(bgImgV)]];
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        UIImageView *imgV;
        if (_adspot.showLogoRequire) {
            // 添加Logo
            NSAssert(_adspot.logoImage != nil, @"showLogoRequire = YES时, 必须设置logoImage");
            CGFloat real_w = [UIScreen mainScreen].bounds.size.width;
            CGFloat real_h = _adspot.logoImage.size.height*(real_w/_adspot.logoImage.size.width);
            UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-real_h, real_w, real_h)];
            imgV.userInteractionEnabled = YES;
            imgV.image = _adspot.logoImage;
        }

            [self.mercury_ad showAdWithBottomView:_adspot.showLogoRequire?imgV:nil skipView:nil];
    });
}




- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [self deallocAdapter];
}

- (void)deallocAdapter {
//    ADV_LEVEL_INFO_LOG(@"11===> %s %@", __func__, [NSThread currentThread]);
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    if (self.mercury_ad) {
        id timer0 = [_mercury_ad performSelector:@selector(timer0)];
        [timer0 performSelector:@selector(stopTimer)];

        id timer = [_mercury_ad performSelector:@selector(timer)];
        [timer performSelector:@selector(stopTimer)];
        
        UIViewController *vc = [_mercury_ad performSelector:@selector(splashVC)];
        [vc dismissViewControllerAnimated:NO completion:nil];
        [vc.view removeFromSuperview];
        
        self.delegate = nil;
        _mercury_ad.delegate = nil;
        _mercury_ad = nil;
    }
}

// MARK: ======================= MercurySplashAdDelegate =======================
- (void)mercury_splashAdDidLoad:(MercurySplashAd *)splashAd {
    _supplier.supplierPrice = splashAd.price;
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];

    if (_supplier.isParallel == YES) {
        _supplier.state = AdServerBidSdkSupplierStateSuccess;
        return;
    }
    [self unifiedDelegate];
}

- (void)mercury_splashAdExposured:(MercurySplashAd *)splashAd {

    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)] && self.mercury_ad) {

        [self.delegate adServerBidExposured];
    }
}

- (void)mercury_splashAdFailError:(nullable NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) { // 并行不释放 只上报
        
        return;
    } else { //
        [self deallocAdapter];
    }

//    if ([self.delegate respondsToSelector:@selector(adServerBidSplashOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidSplashOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
}

- (void)mercury_splashAdClicked:(MercurySplashAd *)splashAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}

- (void)mercury_splashAdLifeTime:(NSUInteger)time {
    if (time <= 0 && [self.delegate respondsToSelector:@selector(adServerBidSplashOnAdCountdownToZero)]) {
        [self.delegate adServerBidSplashOnAdCountdownToZero];
    }
    
    if (self.isGMBidding == 0) {
        return;
    }
    if (time <= 0 && [self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

- (void)mercury_splashAdSkipClicked:(MercurySplashAd *)splashAd {
    if ([self.delegate respondsToSelector:@selector(adServerBidSplashOnAdSkipClicked)]) {
        [self.delegate adServerBidSplashOnAdSkipClicked];
    }
}

- (void)mercury_splashAdClosed:(MercurySplashAd *)splashAd {
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
    [self showAd];
}

@end