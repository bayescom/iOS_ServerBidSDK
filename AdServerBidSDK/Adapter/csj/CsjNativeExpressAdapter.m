//
//  CsjNativeExpressAdapter.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "CsjNativeExpressAdapter.h"
#if __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#else
#import "BUAdSDK.h"
#endif
#import "AdServerBidNativeExpress.h"
#import "AdvLog.h"
#import "AdServerBidNativeExpressView.h"
@interface CsjNativeExpressAdapter () <BUNativeExpressAdViewDelegate>
@property (nonatomic, strong) BUNativeExpressAdManager *csj_ad;
@property (nonatomic, weak) AdServerBidNativeExpress *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, strong) NSArray <__kindof AdServerBidNativeExpressView *> * views;

@end

@implementation CsjNativeExpressAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        
        BUAdSlot *slot = [[BUAdSlot alloc] init];
        slot.ID = _supplier.sdk_adspot_id;
        slot.AdType = BUAdSlotAdTypeFeed;
        slot.position = BUAdSlotPositionFeed;
        slot.imgSize = [BUSize sizeBy:BUProposalSize_Feed228_150];
        _csj_ad = [[BUNativeExpressAdManager alloc] initWithSlot:slot adSize:_adspot.adSize];
        _csj_ad.delegate = self;

    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载穿山甲 supplier: %@", _supplier);
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    [_csj_ad loadAdDataWithCount:1];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"穿山甲加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"穿山甲 成功");
    if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdLoadSuccess:)]) {
        [_delegate adServerBidNativeExpressOnAdLoadSuccess:self.views];
    }
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"穿山甲 失败");
    [self.adspot loadNextSupplierIfHas];
}


- (void)loadAd {
    [super loadAd];
}

- (void)deallocAdapter {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    if (self.csj_ad) {
        self.csj_ad.delegate = nil;
        self.csj_ad = nil;
    }
}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [self deallocAdapter];
}

// MARK: ======================= BUNativeExpressAdViewDelegate =======================
- (void)nativeExpressAdSuccessToLoad:(id)nativeExpressAd views:(nonnull NSArray<__kindof BUNativeExpressAdView *> *)views {
    if (views == nil || views.count == 0) {
        [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:[NSError errorWithDomain:@"" code:100000 userInfo:@{@"msg":@"无广告返回"}]];
        _supplier.state = AdServerBidSdkSupplierStateFailed;
        if (_supplier.isParallel == YES) { // 并行不释放 只上报
            return;
        }

//        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//            [_delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:[NSError errorWithDomain:@"" code:100000 userInfo:@{@"msg":@"无广告返回"}]];
//        }
    } else {
        [_adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
        [_adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
        
        NSMutableArray *temp = [NSMutableArray array];

        for (BUNativeExpressAdView *view in views) {
//            view.rootViewController = _adspot.viewController;
            
            AdServerBidNativeExpressView *TT = [[AdServerBidNativeExpressView alloc] initWithViewController:_adspot.viewController];
            TT.expressView = view;
            TT.identifier = _supplier.identifier;
            TT.price = _supplier.sdk_price;
            [temp addObject:TT];

        }
        
        self.views = temp;
        if (_supplier.isParallel == YES) {
            _supplier.state = AdServerBidSdkSupplierStateSuccess;
            return;
        }

        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdLoadSuccess:)]) {
            [_delegate adServerBidNativeExpressOnAdLoadSuccess:self.views];
        }
    }
}

- (void)nativeExpressAdFailToLoad:(BUNativeExpressAdManager *)nativeExpressAd error:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
//    if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//        [_delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) { // 并行不释放 只上报
        return;
    }

    _csj_ad = nil;
}

- (void)nativeExpressAdViewRenderSuccess:(BUNativeExpressAdView *)nativeExpressAdView {
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdRenderSuccess:)]) {
            [_delegate adServerBidNativeExpressOnAdRenderSuccess:expressView];
        }
    }
}

- (void)nativeExpressAdViewRenderFail:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
//    [_adspot reportWithType:AdServerBidSdkSupplierRepoFaileded error:error];
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdRenderFail:)]) {
            [_delegate adServerBidNativeExpressOnAdRenderFail:expressView];
        }
    }
//    _csj_ad = nil;
}

- (void)nativeExpressAdViewWillShow:(BUNativeExpressAdView *)nativeExpressAdView {
    [_adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdShow:)]) {
            [_delegate adServerBidNativeExpressOnAdShow:expressView];
        }
    }
}

- (void)nativeExpressAdViewDidClick:(BUNativeExpressAdView *)nativeExpressAdView {
    [_adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClicked:)]) {
            [_delegate adServerBidNativeExpressOnAdClicked:expressView];
        }
    }
}

- (void)nativeExpressAdViewPlayerDidPlayFinish:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
//    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
//    if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//        [_delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:error];
//    }
//    _csj_ad = nil;
}

- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterWords {
    
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)nativeExpressAdView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClosed:)]) {
            [_delegate adServerBidNativeExpressOnAdClosed:expressView];
        }
    }
}
- (void)nativeExpressAdViewWillPresentScreen:(BUNativeExpressAdView *)nativeExpressAdView {
    
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
