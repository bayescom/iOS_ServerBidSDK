//
//  GdtNativeExpressAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "GdtNativeExpressAdapter.h"

#if __has_include(<GDTNativeExpressAd.h>)
#import <GDTNativeExpressAd.h>
#else
#import "GDTNativeExpressAd.h"
#endif
#if __has_include(<GDTNativeExpressAdView.h>)
#import <GDTNativeExpressAdView.h>
#else
#import "GDTNativeExpressAdView.h"
#endif

#import "AdServerBidNativeExpress.h"
#import "AdvLog.h"
#import "AdServerBidNativeExpressView.h"

@interface GdtNativeExpressAdapter () <GDTNativeExpressAdDelegete>
@property (nonatomic, strong) GDTNativeExpressAd *gdt_ad;
@property (nonatomic, weak) AdServerBidNativeExpress *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, strong) NSArray<__kindof AdServerBidNativeExpressView *> *views;
@end

@implementation GdtNativeExpressAdapter


- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        _gdt_ad = [[GDTNativeExpressAd alloc] initWithPlacementId:_supplier.sdk_adspot_id
                                                           adSize:_adspot.adSize];
        _gdt_ad.videoMuted = YES;
    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载广点通 supplier: %@", _supplier);
    _gdt_ad.delegate = self;
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    [_gdt_ad loadAd:1];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"广点通加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"广点通 成功");
    if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdLoadSuccess:)]) {
        [_delegate adServerBidNativeExpressOnAdLoadSuccess:self.views];
    }
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"广点通 失败");
    [self.adspot loadNextSupplierIfHas];
}


- (void)loadAd {
    [super loadAd];
}

- (void)deallocAdapter {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    if (self.gdt_ad) {
        self.gdt_ad.delegate = nil;
        self.gdt_ad = nil;
    }
}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);

    [self deallocAdapter];
//    ADVLog(@"%s", __func__);
}



// MARK: ======================= GDTNativeExpressAdDelegete =======================
/**
 * 拉取广告成功的回调
 */
- (void)nativeExpressAdSuccessToLoad:(GDTNativeExpressAd *)nativeExpressAd views:(NSArray<__kindof GDTNativeExpressAdView *> *)views {
    if (views == nil || views.count == 0) {
        [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:nil];
        _supplier.state = AdServerBidSdkSupplierStateFailed;
        if (_supplier.isParallel == YES) {
            return;
        }

//        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//            [_delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:[NSError errorWithDomain:@"" code:100000 userInfo:@{@"msg":@"无广告返回"}]];
//        }
    } else {
        _supplier.supplierPrice = views.firstObject.eCPM;
        [_adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
        [_adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
        
        NSMutableArray *temp = [NSMutableArray array];
        for (GDTNativeExpressAdView *view in views) {
//            view.controller = _adspot.viewController;
            
            AdServerBidNativeExpressView *TT = [[AdServerBidNativeExpressView alloc] initWithViewController:_adspot.viewController];
            TT.expressView = view;
            TT.identifier = _supplier.identifier;
            TT.price = (view.eCPM == 0) ?  _supplier.supplierPrice : view.eCPM;
            [temp addObject:TT];

        }
        
        self.views = temp;
        if (_supplier.isParallel == YES) {
//            NSLog(@"修改状态: %@", _supplier);
            _supplier.state = AdServerBidSdkSupplierStateSuccess;
            return;
        }

        
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdLoadSuccess:)]) {
            [_delegate adServerBidNativeExpressOnAdLoadSuccess:temp];
        }
        
    }
}

/**
 * 拉取广告失败的回调
 */
- (void)nativeExpressAdFailToLoad:(GDTNativeExpressAd *)nativeExpressAd error:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
//    if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//        [_delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }

    _gdt_ad = nil;
}

/**
 * 渲染原生模板广告失败
 */
- (void)nativeExpressAdViewRenderFail:(GDTNativeExpressAdView *)nativeExpressAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:nil];
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];
    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdRenderFail:)]) {
            [_delegate adServerBidNativeExpressOnAdRenderFail:expressView];
        }
    }
//    if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//        [_delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:[NSError errorWithDomain:@"" code:10000 userInfo:@{@"msg": @"渲染原生模板广告失败"}]];
//    }
    _gdt_ad = nil;
}

- (void)nativeExpressAdViewRenderSuccess:(GDTNativeExpressAdView *)nativeExpressAdView {
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdRenderSuccess:)]) {
            [_delegate adServerBidNativeExpressOnAdRenderSuccess:expressView];
        }
    }
    
}

- (void)nativeExpressAdViewClicked:(GDTNativeExpressAdView *)nativeExpressAdView {
    [_adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];
    
    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClicked:)]) {
            [_delegate adServerBidNativeExpressOnAdClicked:expressView];
        }
    }
}

- (void)nativeExpressAdViewClosed:(GDTNativeExpressAdView *)nativeExpressAdView {
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];
    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClosed:)]) {
            [_delegate adServerBidNativeExpressOnAdClosed:expressView];
        }
    }
}

- (void)nativeExpressAdViewExposure:(GDTNativeExpressAdView *)nativeExpressAdView {
    [_adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdShow:)]) {
            [_delegate adServerBidNativeExpressOnAdShow:expressView];
        }
    }
}


- (void)nativeExpressAdViewWillPresentVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {
    
}

- (void)nativeExpressAdViewDidPresentVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {

}

- (void)nativeExpressAdViewWillDismissVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {

}

- (void)nativeExpressAdViewDidDismissVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {
    
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
