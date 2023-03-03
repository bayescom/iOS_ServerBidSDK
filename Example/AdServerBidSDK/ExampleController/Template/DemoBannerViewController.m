//
//  DemoBannerViewController.m
//  Example
//
//  Created by CherryKing on 2019/11/8.
//  Copyright © 2019 CherryKing. All rights reserved.
//

#import "DemoBannerViewController.h"
#import "ViewBuilder.h"
#import "AdvSdkConfig.h"
#import <AdServerBidSDK/AdServerBidBanner.h>

@interface DemoBannerViewController () <AdServerBidBannerDelegate>
@property (nonatomic, strong) AdServerBidBanner *adServerBidBanner;
@property (nonatomic, strong) UIView *contentV;

@end

@implementation DemoBannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.initDefSubviewsFlag = YES;
    self.adspotIdsArr = @[
        @{@"addesc": @"Banner", @"adspotId": @"100255-10000558"},
    ];
    self.btn1Title = @"加载并显示广告";
}

- (void)loadAdBtn1Action {
    if (![self checkAdspotId]) { return; }
    if (!_contentV) {
        _contentV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width*5/32.0)];
    }
    [self.adShowView addSubview:self.contentV];
    self.adShowView.hidden = NO;

//    self.adServerBidBanner = [[AdServerBidBanner alloc] initWithAdspotId:@"11111113" adContainer:self.contentV viewController:self];
//    self.adServerBidBanner = [[AdServerBidBanner alloc] initWithAdspotId:self.adspotId adContainer:self.contentV viewController:self];
    self.adServerBidBanner = [[AdServerBidBanner alloc] initWithAdspotId:self.adspotId adContainer:self.contentV customExt:self.ext viewController:self];
    self.adServerBidBanner.delegate = self;
    
    [self.adServerBidBanner loadAd];
    
}

// MARK: ======================= AdServerBidBannerDelegate =======================
/// 广告数据拉取成功回调
- (void)adServerBidUnifiedViewDidLoad {
    NSLog(@"广告数据拉取成功 %s", __func__);
}

/// 广告加载失败
- (void)adServerBidFailedWithError:(NSError *)error description:(NSDictionary *)description{
    NSLog(@"广告展示失败 %s  error: %@ 详情:%@", __func__, error, description);

}

/// 内部渠道开始加载时调用
- (void)adServerBidSupplierWillLoad:(NSString *)supplierId {
    NSLog(@"内部渠道开始加载 %s  supplierId: %@", __func__, supplierId);

}

/// 广告曝光
- (void)adServerBidExposured {
    NSLog(@"广告曝光回调 %s", __func__);
}

/// 广告点击
- (void)adServerBidClicked {
    NSLog(@"广告点击 %s", __func__);
}

/// 广告关闭回调
- (void)adServerBidDidClose {
    NSLog(@"广告关闭了 %s", __func__);
}

/// 策略请求成功
- (void)adServerBidOnAdReceived:(NSString *)reqId {
    NSLog(@"%s 策略id为: %@",__func__ , reqId);
}

@end
