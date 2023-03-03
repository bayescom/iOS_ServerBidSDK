//
//  KsRewardVideoAdapter.m
//  AdServerBidSDK
//
//  Created by MS on 2021/4/23.
//

#import "KsRewardVideoAdapter.h"
#if __has_include(<KSAdSDK/KSAdSDK.h>)
#import <KSAdSDK/KSAdSDK.h>
#else
//#import "KSAdSDK.h"
#endif

#import "AdServerBidRewardVideo.h"
#import "UIApplication+Adv.h"
#import "AdvLog.h"
@interface KsRewardVideoAdapter ()<KSRewardedVideoAdDelegate>
@property (nonatomic, strong) KSRewardedVideoAd *ks_ad;
@property (nonatomic, weak) AdServerBidRewardVideo *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, assign) BOOL isCached;

@end

@implementation KsRewardVideoAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        KSRewardedVideoModel *model = [KSRewardedVideoModel new];
        _ks_ad = [[KSRewardedVideoAd alloc] initWithPosId:supplier.sdk_adspot_id rewardedVideoModel:model];
        _ks_ad.showDirection = KSAdShowDirection_Vertical;
    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载快手 supplier: %@", _supplier);
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    self.ks_ad.delegate = self;
    [self.ks_ad loadAdData];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"快手加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"快手 成功");
    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }
    
    if (_isCached) {
        if ([self.delegate respondsToSelector:@selector(adServerBidRewardVideoOnAdVideoCached)]) {
            [self.delegate adServerBidRewardVideoOnAdVideoCached];
        }
    }
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"快手 失败");
    [self.adspot loadNextSupplierIfHas];
}



- (void)loadAd {
    [super loadAd];
}

- (void)showAd {
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        if (self.ks_ad.isValid) {
            [self.ks_ad showAdFromRootViewController:self.adspot.viewController.navigationController];
        }
    });

}

- (void)deallocAdapter {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    if (self.ks_ad) {
        self.ks_ad.delegate = nil;
        self.ks_ad = nil;
    }
}


- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [self deallocAdapter];
}

/**
 This method is called when video ad material loaded successfully.
 */
- (void)rewardedVideoAdDidLoad:(KSRewardedVideoAd *)rewardedVideoAd {
    _supplier.supplierPrice = rewardedVideoAd.ecpm;
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
    
//    NSLog(@"广点通激励视频拉取成功 %@",self.ks_ad);
    if (_supplier.isParallel == YES) {
//        NSLog(@"修改状态: %@", _supplier);
        _supplier.state = AdServerBidSdkSupplierStateSuccess;
        return;
    }

    if ([self.delegate respondsToSelector:@selector(adServerBidUnifiedViewDidLoad)]) {
        [self.delegate adServerBidUnifiedViewDidLoad];
    }

}
/**
 This method is called when video ad materia failed to load.
 @param error : the reason of error
 */
- (void)rewardedVideoAd:(KSRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
//    NSLog(@"快手 错误 %@", error);
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }

}
/**
 This method is called when cached successfully.
 */
- (void)rewardedVideoAdVideoDidLoad:(KSRewardedVideoAd *)rewardedVideoAd {
    if (_supplier.isParallel == YES) {
        _isCached = YES;
        return;
    }
    if ([self.delegate respondsToSelector:@selector(adServerBidRewardVideoOnAdVideoCached)]) {
        [self.delegate adServerBidRewardVideoOnAdVideoCached];
    }
}
/**
 This method is called when video ad slot will be showing.
 */
- (void)rewardedVideoAdWillVisible:(KSRewardedVideoAd *)rewardedVideoAd {
    
}
/**
 This method is called when video ad slot has been shown.
 */
- (void)rewardedVideoAdDidVisible:(KSRewardedVideoAd *)rewardedVideoAd {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
}
/**
 This method is called when video ad is about to close.
 */
- (void)rewardedVideoAdWillClose:(KSRewardedVideoAd *)rewardedVideoAd {
    
}
/**
 This method is called when video ad is closed.
 */
- (void)rewardedVideoAdDidClose:(KSRewardedVideoAd *)rewardedVideoAd {
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
}

/**
 This method is called when video ad is clicked.
 */
- (void)rewardedVideoAdDidClick:(KSRewardedVideoAd *)rewardedVideoAd  {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
}
/**
 This method is called when video ad play completed or an error occurred.
 @param error : the reason of error
 */
- (void)rewardedVideoAdDidPlayFinish:(KSRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    if (!error) {
        if ([self.delegate respondsToSelector:@selector(adServerBidRewardVideoAdDidPlayFinish)]) {
            [self.delegate adServerBidRewardVideoAdDidPlayFinish];
        }
    }
}
/**
 This method is called when the user clicked skip button.
 */
- (void)rewardedVideoAdDidClickSkip:(KSRewardedVideoAd *)rewardedVideoAd {
    
}
/**
 This method is called when the video begin to play.
 */
- (void)rewardedVideoAdStartPlay:(KSRewardedVideoAd *)rewardedVideoAd {
    
}
/**
 This method is called when the user close video ad.
 */
- (void)rewardedVideoAd:(KSRewardedVideoAd *)rewardedVideoAd hasReward:(BOOL)hasReward {
    if (hasReward) {
        if ([self.delegate respondsToSelector:@selector(adServerBidRewardVideoAdDidRewardEffective:)]) {
            [self.delegate adServerBidRewardVideoAdDidRewardEffective:hasReward];
        }
    }
}



@end
