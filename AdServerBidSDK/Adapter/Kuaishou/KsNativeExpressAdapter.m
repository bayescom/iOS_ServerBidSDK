//
//  KsNativeExpressAdapter.m
//  AdServerBidSDK
//
//  Created by MS on 2021/4/23.
//

#import "KsNativeExpressAdapter.h"
#if __has_include(<KSAdSDK/KSAdSDK.h>)
#import <KSAdSDK/KSAdSDK.h>
#else
//#import "KSAdSDK.h"
#endif


#import "AdServerBidNativeExpress.h"
#import "AdvLog.h"
#import "AdServerBidNativeExpressView.h"
@interface KsNativeExpressAdapter ()<KSFeedAdsManagerDelegate, KSFeedAdDelegate>
@property (nonatomic, strong) KSFeedAdsManager *ks_ad;
@property (nonatomic, weak) AdServerBidNativeExpress *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, strong) NSArray<AdServerBidNativeExpressView *> * views;

@end

@implementation KsNativeExpressAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        
        _ks_ad = [[KSFeedAdsManager alloc] initWithPosId:_supplier.sdk_adspot_id size:_adspot.adSize];
    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载快手 supplier: %@", _supplier);
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    _ks_ad.delegate = self;
    [_ks_ad loadAdDataWithCount:1];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"快手加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"快手 成功");
    if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdLoadSuccess:)]) {
        [_delegate adServerBidNativeExpressOnAdLoadSuccess:self.views];
    }
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"快手 失败");
    [self.adspot loadNextSupplierIfHas];
}


- (void)loadAd {
    [super loadAd];
    
}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [self deallocAdapter];
}

- (void)deallocAdapter {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);

    if (self.ks_ad) {
        self.ks_ad.delegate = nil;
        self.ks_ad = nil;
    }
}


- (void)feedAdsManagerSuccessToLoad:(KSFeedAdsManager *)adsManager nativeAds:(NSArray<KSFeedAd *> *_Nullable)feedAdDataArray {
//    self.title = @"数据加载成功";
    if (feedAdDataArray == nil || feedAdDataArray.count == 0) {
        [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:[NSError errorWithDomain:@"" code:100000 userInfo:@{@"msg":@"无广告返回"}]];
        _supplier.state = AdServerBidSdkSupplierStateFailed;
        if (_supplier.isParallel == YES) { // 并行不释放 只上报
            return;
        }

//        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdFailedWithSdkId:error:)]) {
//            [_delegate adServerBidNativeExpressOnAdFailedWithSdkId:_supplier.identifier error:[NSError errorWithDomain:@"" code:100000 userInfo:@{@"msg":@"无广告返回"}]];
//        }
    } else {
        _supplier.supplierPrice = feedAdDataArray.firstObject.ecpm;
        [_adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
        [_adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
        NSMutableArray *temp = [NSMutableArray array];
        for (KSFeedAd *ad in feedAdDataArray) {
            ad.delegate = self;
//            ad.videoSoundEnable = NO;
//            [ad setVideoSoundEnable:NO];
            
            AdServerBidNativeExpressView *TT = [[AdServerBidNativeExpressView alloc] initWithViewController:_adspot.viewController];
            TT.expressView = ad.feedView;
            TT.identifier = _supplier.identifier;
            TT.price = (ad.ecpm == 0) ?  _supplier.supplierPrice : ad.ecpm;
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

//    [self refreshWithData:adsManager];
}

- (void)feedAdsManager:(KSFeedAdsManager *)adsManager didFailWithError:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
}

- (void)feedAdViewWillShow:(KSFeedAd *)feedAd {
    [_adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)feedAd.feedView];
    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdShow:)]) {
            [_delegate adServerBidNativeExpressOnAdShow:expressView];
        }
    }


}

- (void)feedAdDidClick:(KSFeedAd *)feedAd {
    [_adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)feedAd.feedView];

    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClicked:)]) {
            [_delegate adServerBidNativeExpressOnAdClicked:expressView];
        }
    }
}

- (void)feedAdDislike:(KSFeedAd *)feedAd {
    AdServerBidNativeExpressView *expressView = [self returnExpressViewWithAdView:(UIView *)feedAd.feedView];
    if (expressView) {
        if ([_delegate respondsToSelector:@selector(adServerBidNativeExpressOnAdClosed:)]) {
            [_delegate adServerBidNativeExpressOnAdClosed:expressView];
        }
    }
}

- (void)feedAdDidShowOtherController:(KSFeedAd *)nativeAd interactionType:(KSAdInteractionType)interactionType {
    
}

- (void)feedAdDidCloseOtherController:(KSFeedAd *)nativeAd interactionType:(KSAdInteractionType)interactionType {
    
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
