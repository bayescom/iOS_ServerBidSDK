//
//  KsSplashAdapter.m
//  AdServerBidSDK
//
//  Created by MS on 2021/4/20.
//

#import "KsSplashAdapter.h"

#if __has_include(<KSAdSDK/KSAdSDK.h>)
#import <KSAdSDK/KSAdSDK.h>
#else
//#import "KSAdSDK.h"
#endif

#import "AdServerBidSplash.h"
#import "UIApplication+Adv.h"
#import "AdvLog.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define WeakSelf(type) __weak typeof(type) weak##type = type;
#define StrongSelf(type) __strong typeof(weak##type) strong##type = weak##type;

@interface KsSplashAdapter ()<KSSplashAdViewDelegate>
{
     
    NSInteger _timeout;
    NSInteger _timeout_stamp;

}

@property (nonatomic, weak) AdServerBidSplash *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;

// 剩余时间，用来判断用户是点击跳过，还是正常倒计时结束
@property (nonatomic, assign) NSUInteger leftTime;
// 是否点击了
@property (nonatomic, assign) BOOL isClick;
@property (nonatomic, assign) BOOL isCanch;
@property (nonatomic, strong) KSSplashAdView *ks_ad;
@property (nonatomic, strong) UIImageView *imgV;



@end

@implementation KsSplashAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        _leftTime = 5;  // 默认5s
        _ks_ad = [[KSSplashAdView alloc] initWithPosId:_supplier.sdk_adspot_id];
        _ks_ad.delegate = self;
    //    _ks_ad.needShowMiniWindow = NO;
        _ks_ad.rootViewController = _adspot.viewController;
    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载快手 supplier: %@", _supplier);
    
    _supplier.state = AdServerBidSdkSupplierStateInPull; // 从请求广告到结果确定前
    NSInteger parallel_timeout = _supplier.timeout;
    if (parallel_timeout == 0) {
        parallel_timeout = 3000;
    }
    _ks_ad.timeoutInterval = parallel_timeout / 1000.0;
    
    [_ks_ad loadAdData];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"快手加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"快手 成功");
    [self unifiedDelegate];
    
}

- (void)supplierRequestToken {
    ADV_LEVEL_INFO_LOG(@"快手 请求token");
    KSAdBiddingAdModel *model = [KSAdBiddingAdModel new];
    model.posId = _supplier.sdk_adspot_id;

    NSString *token = [KSAdSDKManager getBidRequestToken:model];
    _supplier.token = token;
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBiddingToken supplier:_supplier error:nil];
    NSLog(@"快手token: %@", token);

}


- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"快手 失败");
    [self.adspot loadNextSupplierIfHas];
    [self deallocAdapter];
}


- (void)loadAd {
    [super loadAd];
}

- (void)deallocAdapter {
    //    _gdt_ad = nil;
    //    dispatch_async(dispatch_get_main_queue(), ^{
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    if (_ks_ad) {
        [_ks_ad removeFromSuperview];
        _ks_ad.delegate = nil;
        _ks_ad = nil;
//        _supplier = nil;
    }
    [self.imgV removeFromSuperview];
    self.imgV = nil;
    //    });
    
}

- (void)gmShowAd {
    [self showAdAction];
}

- (void)showAd {
    NSNumber *isGMBidding = ((NSNumber * (*)(id, SEL))objc_msgSend)((id)self.adspot, @selector(isGMBidding));

    if (isGMBidding.integerValue == 1) {
        return;
    }
    [self showAdAction];
}

- (void)showAdAction {
    if (!_ks_ad) {
        return;
    }
    // 设置logo
    CGRect adFrame = [UIScreen mainScreen].bounds;
    if (_adspot.logoImage && _adspot.showLogoRequire) {
        
        NSAssert(_adspot.logoImage != nil, @"showLogoRequire = YES时, 必须设置logoImage");
        CGFloat real_w = [UIScreen mainScreen].bounds.size.width;
        CGFloat real_h = _adspot.logoImage.size.height*(real_w/_adspot.logoImage.size.width);
        adFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-real_h);
        
        self.imgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-real_h, real_w, real_h)];
        self.imgV.userInteractionEnabled = YES;
        self.imgV.image = _adspot.logoImage;
        [[UIApplication sharedApplication].adv_getCurrentWindow addSubview:self.imgV];
    }
    _ks_ad.frame = adFrame;
    [_ks_ad showInView:[UIApplication sharedApplication].adv_getCurrentWindow];

}


/**
 * splash ad request done
 */
- (void)ksad_splashAdDidLoad:(KSSplashAdView *)splashAdView {

}
/**
 * splash ad material load, ready to display
 */
- (void)ksad_splashAdContentDidLoad:(KSSplashAdView *)splashAdView {
    _supplier.supplierPrice = splashAdView.ecpm;
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoBidding supplier:_supplier error:nil];
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoSucceeded supplier:_supplier error:nil];
    if (_supplier.isParallel == YES) {
        _supplier.state = AdServerBidSdkSupplierStateSuccess;
        return;
    }
    [self unifiedDelegate];

}
/**
 * splash ad (material) failed to load
 */
- (void)ksad_splashAd:(KSSplashAdView *)splashAdView didFailWithError:(NSError *)error {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoFaileded supplier:_supplier error:error];
    _supplier.state = AdServerBidSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }
    [self deallocAdapter];
}
/**
 * splash ad did visible
 */
- (void)ksad_splashAdDidVisible:(KSSplashAdView *)splashAdView {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidExposured)]) {
        [self.delegate adServerBidExposured];
    }
    
    _timeout = 5;
    // 记录过期的时间
    _timeout_stamp = ([[NSDate date] timeIntervalSince1970] + _timeout)*1000;

}
/**
 * splash ad video begin play
 * for video ad only
 */
- (void)ksad_splashAdVideoDidBeginPlay:(KSSplashAdView *)splashAdView {

}
/**
 * splash ad clicked
 * @param inMiniWindow whether click in mini window
 */
- (void)ksad_splashAd:(KSSplashAdView *)splashAdView didClick:(BOOL)inMiniWindow {
    [self.adspot reportWithType:AdServerBidSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(adServerBidClicked)]) {
        [self.delegate adServerBidClicked];
    }
    [self ksadDidClose];
    [_imgV removeFromSuperview];
    _imgV = nil;
}
/**   * splash ad will zoom out, frame can be assigned
 * for video ad only
 * @param frame target frame
 */
- (void)ksad_splashAd:(KSSplashAdView *)splashAdView willZoomTo:(inout CGRect *)frame {
    
}
/**
 * splash ad zoomout view will move to frame
 * @param frame target frame
 */
- (void)ksad_splashAd:(KSSplashAdView *)splashAdView willMoveTo:(inout CGRect *)frame {
    
}
/**
 * splash ad skipped
 * @param showDuration  splash show duration (no subsequent callbacks, remove & release KSSplashAdView here)
 */
- (void)ksad_splashAd:(KSSplashAdView *)splashAdView didSkip:(NSTimeInterval)showDuration {
//    NSLog(@"----%@", NSStringFromSelector(_cmd));
    if ([self.delegate respondsToSelector:@selector(adServerBidSplashOnAdSkipClicked)]) {
        [self.delegate adServerBidSplashOnAdSkipClicked];
    }
    
    [self ksadDidClose];
//    [self deallocAdapter];
}
/**
 * splash ad close conversion viewcontroller (no subsequent callbacks, remove & release KSSplashAdView here)
 */
- (void)ksad_splashAdDidCloseConversionVC:(KSSplashAdView *)splashAdView interactionType:(KSAdInteractionType)interactType {
    

    [self ksadDidClose];

}

/**
 * splash ad play finished & auto dismiss (no subsequent callbacks, remove & release KSSplashAdView here)
 */
- (void)ksad_splashAdDidAutoDismiss:(KSSplashAdView *)splashAdView {

    [self ksadDidClose];
}
/**
 * splash ad close by user (zoom out mode) (no subsequent callbacks, remove & release KSSplashAdView here)
 */
- (void)ksad_splashAdDidClose:(KSSplashAdView *)splashAdView {

    [self ksadDidClose];
}

- (void)ksadDidClose {
    if ([[NSDate date] timeIntervalSince1970]*1000 < _timeout_stamp) {// 关闭时的时间小于过期时间则点击了跳过

    } else {
        if ([self.delegate respondsToSelector:@selector(adServerBidSplashOnAdCountdownToZero)]) {
            [self.delegate adServerBidSplashOnAdCountdownToZero];
        }
    }
    if ([self.delegate respondsToSelector:@selector(adServerBidDidClose)]) {
        [self.delegate adServerBidDidClose];
    }
    [self deallocAdapter];

}


- (UIImageView *)imgV {
    if (!_imgV) {
        _imgV = [[UIImageView alloc] init];
    }
    return _imgV;
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
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [self deallocAdapter];
}
@end
