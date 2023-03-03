//
//  DemoInterstitialViewController.m
//  adServerBidlib
//
//  Created by allen on 2019/12/31.
//  Copyright © 2019 Bayescom. All rights reserved.
//

#import "DemoInterstitialViewController.h"
#import "DemoUtils.h"

#import <AdServerBidSDK/AdServerBidInterstitial.h>

@interface DemoInterstitialViewController () <AdServerBidInterstitialDelegate>
@property (nonatomic, strong) AdServerBidInterstitial *adServerBidInterstitial;
@property (nonatomic) bool isAdLoaded;
@end

@implementation DemoInterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.initDefSubviewsFlag = YES;
    self.adspotIdsArr = @[
        @{@"addesc": @"mediaId-adspotId", @"adspotId": @"100255-10000559"},
        @{@"addesc": @"mediaId-adspotId", @"adspotId": @"100255-10006501"},
        @{@"addesc": @"mediaId-adspotId", @"adspotId": @"102194-10007006"},
    ];
    self.btn1Title = @"加载广告";
    self.btn2Title = @"显示广告";
}

- (void)loadAdBtn1Action {
    if (![self checkAdspotId]) { return; }
    

    self.adServerBidInterstitial = [[AdServerBidInterstitial alloc] initWithAdspotId:self.adspotId
                                                              viewController:self];
        self.adServerBidInterstitial.delegate = self;
    _isAdLoaded=false;
    [self.adServerBidInterstitial loadAd];
}

- (void)loadAdBtn2Action {
    if (!_isAdLoaded) {
       [JDStatusBarNotification showWithStatus:@"请先加载广告" dismissAfter:1.5];
        return;
    }
    [self.adServerBidInterstitial showAd];
}

// MARK: ======================= AdServerBidInterstitialDelegate =======================

/// 请求广告数据成功后调用
- (void)adServerBidUnifiedViewDidLoad {
    NSLog(@"广告数据拉取成功 %s", __func__);
    _isAdLoaded=true;
    [JDStatusBarNotification showWithStatus:@"广告加载成功" dismissAfter:1.5];
    [self loadAdBtn2Action];
}

/// 广告曝光
- (void)adServerBidExposured {
    NSLog(@"广告曝光回调 %s", __func__);
}

/// 广告点击
- (void)adServerBidClicked {
    NSLog(@"广告点击 %s", __func__);
}

/// 广告加载失败
- (void)adServerBidFailedWithError:(NSError *)error description:(NSDictionary *)description {
    [JDStatusBarNotification showWithStatus:@"广告加载失败" dismissAfter:1.5];
    NSLog(@"广告展示失败 %s  error: %@ 详情:%@", __func__, error, description);

}



/// 内部渠道开始加载时调用
- (void)adServerBidSupplierWillLoad:(NSString *)supplierId {
    NSLog(@"内部渠道开始加载 %s  supplierId: %@", __func__, supplierId);

}

/// 广告关闭了
- (void)adServerBidDidClose {
    NSLog(@"广告关闭了 %s", __func__);
}

/// 策略请求成功
- (void)adServerBidOnAdReceived:(NSString *)reqId {
    NSLog(@"%s 策略id为: %@",__func__ , reqId);
}


@end
