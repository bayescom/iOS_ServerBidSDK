//
//  MercuryNativeExpressAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "MercuryNativeExpressAdapter.h"
#if __has_include(<MercurySDK/MercuryNativeExpressAd.h>)
#import <MercurySDK/MercuryNativeExpressAd.h>
#else
#import "MercuryNativeExpressAd.h"
#endif
#import "AdServerBidNativeExpress.h"
#import "AdvLog.h"
#import "AdServerBidNativeExpressView.h"
@interface MercuryNativeExpressAdapter () <MercuryNativeExpressAdDelegete>
@property (nonatomic, strong) MercuryNativeExpressAd *mercury_ad;
@property (nonatomic, weak) AdServerBidNativeExpress *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, strong) NSArray<AdServerBidNativeExpressView *> * views;

@end

@implementation MercuryNativeExpressAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(AdServerBidNativeExpress *)adspot; {
    if (self = [super init]) {
        _adspot = adspot;
        _supplier = supplier;
        _mercury_ad = [[MercuryNativeExpressAd alloc] initAdWithAdspotId:_supplier.sdk_adspot_id];
        _mercury_ad.videoMuted = YES;
        _mercury_ad.videoPlayPolicy = MercuryVideoAutoPlayPolicyWIFI;
        _mercury_ad.renderSize = _adspot.adSize;

    }
    return self;
}

- (void)loadAd {
    int adCount = 1;
    _mercury_ad.delegate = self;
    ADV_LEVEL_INFO_LOG(@"加载MercurySDK supplier: %@", _supplier);
    if (_supplier.state == AdServerBidSdkSupplierStateSuccess) {// 并行请求保存的状态 再次轮到该渠道加载的时候 直接show
        ADV_LEVEL_INFO_LOG(@"MercurySDK 成功");
        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdLoadSuccess:)]) {
            [self.delegate adServerBidNativeExpressOnAdLoadSuccess:self.views];
        }
//        [self showAd];
    } else if (_supplier.state == AdServerBidSdkSupplierStateFailed) { //失败的话直接对外抛出回调
        ADV_LEVEL_INFO_LOG(@"MercurySDK 失败 %@", _supplier);
        [self.adspot loadNextSupplierIfHas];
    } else if (_supplier.state == AdServerBidSdkSupplierStateInPull) { // 正在请求广告时 什么都不用做等待就行
        ADV_LEVEL_INFO_LOG(@"MercurySDK 正在加载中");
    } else {
        ADV_LEVEL_INFO_LOG(@"MercurySDK load ad");
        _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
        [_mercury_ad loadAdWithCount:adCount];
    }

}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);

    [self deallocAdapter];
//    ADVLog(@"%s", __func__);
}

- (void)deallocAdapter {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);

    if (self.mercury_ad) {
        self.mercury_ad.delegate = nil;
        self.mercury_ad = nil;
    }
}


// MARK: ======================= MercuryNativeExpressAdDelegete =======================
/// 拉取原生模板广告成功 | (注意: nativeExpressAdView在此方法执行结束不被强引用，nativeExpressAd中的对象会被自动释放)
- (void)mercury_nativeExpressAdSuccessToLoad:(id)nativeExpressAd views:(NSArray<MercuryNativeExpressAdView *> *)views {
    if (views == nil || views.count == 0) {
        [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:nil];
//        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//            [self.delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier
//                                                                 error:[NSError errorWithDomain:@"" code:100000 userInfo:@{@"msg": @"无广告返回"}]];
//        }
        _supplier.state = AdServerBidSdkSupplierStateFailed;
        if (_supplier.isParallel == YES) {
            return;
        }

    } else if (self.adspot) {
        _supplier.supplierPrice = views.firstObject.price;
        [_adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
        [_adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
        

        NSMutableArray *temp = [NSMutableArray array];
        for (MercuryNativeExpressAdView *view in views) {
            if ([view isKindOfClass:NSClassFromString(@"MercuryNativeExpressAdView")]) {
                
                AdServerBidNativeExpressView *TT = [[AdServerBidNativeExpressView alloc] initWithViewController:_adspot.viewController];
                TT.expressView = view;
                TT.identifier = _supplier.identifier;
                TT.price = (view.price == 0) ?  _supplier.supplierPrice : view.price;
                [temp addObject:TT];
            }
        }
        
        self.views = temp;
        if (_supplier.isParallel == YES) {
//            NSLog(@"修改状态: %@", _supplier);
            _supplier.state = AdServerBidSdkSupplierStateSuccess;
            return;
        }

        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdLoadSuccess:)]) {
            [self.delegate adServerBidNativeExpressOnAdLoadSuccess:self.views];
        }
    }
}

/// 拉取原生模板广告失败
- (void)mercury_nativeExpressAdFailToLoadWithError:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }
    _mercury_ad = nil;
//    if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//        [self.delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
}

/// 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
- (void)mercury_nativeExpressAdViewRenderSuccess:(MercuryNativeExpressAdView *)nativeExpressAdView {
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];
    if (expressView) {
        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdRenderSuccess:)]) {
            [self.delegate adServerBidNativeExpressOnAdRenderSuccess:expressView];
        }
    }

}

/// 原生模板广告渲染失败
- (void)mercury_nativeExpressAdViewRenderFail:(MercuryNativeExpressAdView *)nativeExpressAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:[NSError errorWithDomain:@"广告素材渲染失败" code:301 userInfo:@{@"msg": @"广告素材渲染失败"}]];
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdRenderFail:)]) {
            [self.delegate adServerBidNativeExpressOnAdRenderFail:expressView];
        }
    }
}

/// 原生模板广告曝光回调
- (void)mercury_nativeExpressAdViewExposure:(MercuryNativeExpressAdView *)nativeExpressAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdShow:)]) {
            [self.delegate adServerBidNativeExpressOnAdShow:expressView];
        }
    }
}

/// 原生模板广告点击回调
- (void)mercury_nativeExpressAdViewClicked:(MercuryNativeExpressAdView *)nativeExpressAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClicked:)]) {
            [self.delegate adServerBidNativeExpressOnAdClicked:expressView];
        }
    }
}

/// 原生模板广告被关闭
- (void)mercury_nativeExpressAdViewClosed:(MercuryNativeExpressAdView *)nativeExpressAdView {
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];
    if (expressView) {
        if ([self.delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClosed:)]) {
            [self.delegate adServerBidNativeExpressOnAdClosed:expressView];
        }
    }
}

- (AdServerBidNativeExpressView *)returnExpressViewWithAdView:(UIView *)adView {
    for (NSInteger i = 0; i < self.views.count; i++) {
        AdServerBidNativeExpressView *temp = self.views[i];
        if (temp.expressView == adView) {
            return temp;
        }
    }
    return nil;
}

@end
