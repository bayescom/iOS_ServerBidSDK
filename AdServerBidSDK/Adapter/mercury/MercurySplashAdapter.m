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

// adserverbidding 环境下
// isServerBidding = YES 意味着MercurySDK 竞价落败
// isServerBidding = NO 意味着MercurySDK 竞价胜出
@property (nonatomic, assign) BOOL isServerBidding;

@end

@implementation MercurySplashAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        [MercuryConfigManager supportHttps:YES];
        _adspot = adspot;
        _supplier = supplier;
        _isServerBidding = NO;
        [MercuryConfigManager openDebug:YES];
//        NSLog(@"==>%@", [MercuryConfigManager sdkVersion]);
        NSLog(@"%@", _supplier.sdkBiddingInfo);
        _mercury_ad = [[MercurySplashAd alloc] initAdWithAdspotId:_supplier.sdk_adspot_id customExt:@{@"sdk_bidding" : _supplier.sdkBiddingInfo} delegate:self];
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
    if (_adspot.timeout) {
        if (_adspot.timeout > 500) {
            _mercury_ad.fetchDelay = _supplier.timeout / 1000.0;
        }
    }
    
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"Mercury加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"Mercury 成功");
    [self unifiedDelegate];
    
}

- (void)supplierRequestToken {
    ADV_LEVEL_INFO_LOG(@"Mercury 加载token");
    [_mercury_ad loadAd];
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
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    if (self.mercury_ad) {
        self.delegate = nil;
        [_mercury_ad destory];
        _mercury_ad = nil;
    }
}

// MARK: ======================= MercurySplashAdDelegate =======================
// 如果是serverBidding 该回调会在 mercury_splashAdDidLoad 前触发
- (void)mercury_splashAdServerBiddingResponse:(MercurySplashAd *)splashAd info:(NSDictionary *)info {
    NSLog(@"bidding info: %@", info);
    _isServerBidding = YES;
    _supplier.winSupplierId = info[@"sdkId"];
    _supplier.winSupplierInfo = info[@"sdkInfo"];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBiddingWinInfo supplier:_supplier error:nil];

}

- (void)mercury_splashAdDidLoad:(MercurySplashAd *)splashAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
    
    // 如果mercurySDK 胜出
    if (!_isServerBidding) {
        _supplier.winSupplierId = SDK_ID_MERCURY;
        _supplier.winSupplierInfo = @"";
        [self.adspot reportWithType:AdServerBidSdkSupplierRepoBiddingWinInfo supplier:_supplier error:nil];
    }

    _supplier.state = AdServerBidSdkSupplierStateSuccess;
    if (_supplier.isParallel == YES) {
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
    NSLog(@"%s  %@", __func__, error);
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
//    if (time <= 0 && [self.delegate respondsToSelector:@selector(adServerBidSplashOnAdCountdownToZero)]) {
//        [self.delegate adServerBidSplashOnAdCountdownToZero];
//    }
    
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

- (void)reportAdExposured {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [_mercury_ad reportAdExposured];
}

- (void)reportAdClicked {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [_mercury_ad reportAdClicked];
}

@end
