//
//  DemoFullScreenVideoController.m
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/13.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "DemoFullScreenVideoController.h"
#import "DemoUtils.h"

#import <AdServerBidSDK/AdServerBidFullScreenVideo.h>

@interface DemoFullScreenVideoController () <AdServerBidFullScreenVideoDelegate>
@property (nonatomic, strong) AdServerBidFullScreenVideo *adServerBidFullScreenVideo;
@property (nonatomic) bool isAdLoaded;

@end

@implementation DemoFullScreenVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.initDefSubviewsFlag = YES;
    self.adspotIdsArr = @[
        @{@"addesc": @"mediaId-adspotId", @"adspotId": @"100255-10004765"},
    ];
    self.btn1Title = @"加载广告";
    self.btn2Title = @"显示广告";
}

- (void)loadAdBtn1Action {
    if (![self checkAdspotId]) { return; }
    
//    self.adServerBidFullScreenVideo = [[AdServerBidFullScreenVideo alloc] initWithAdspotId:@"11111112"
//                                                                    viewController:self];

    self.adServerBidFullScreenVideo = [[AdServerBidFullScreenVideo alloc] initWithAdspotId:self.adspotId
                                                                    viewController:self];
    
//    self.adServerBidFullScreenVideo = [[AdServerBidFullScreenVideo alloc] initWithAdspotId:self.adspotId
//                                                                         customExt:self.ext
//                                                                    viewController:self];
    self.adServerBidFullScreenVideo.delegate = self;
    _isAdLoaded=false;
    [self.adServerBidFullScreenVideo loadAd];
}

- (void)loadAdBtn2Action {
    if (!_isAdLoaded) {
        [JDStatusBarNotification showWithStatus:@"请先加载广告" dismissAfter:1.5];

    }
    [self.adServerBidFullScreenVideo showAd];
}

// MARK: ======================= AdServerBidFullScreenVideoDelegate =======================

/// 请求广告数据成功后调用
- (void)adServerBidUnifiedViewDidLoad {
    NSLog(@"请求广告数据成功后调用 %s", __func__);
}

/// 广告曝光
- (void)adServerBidExposured {
    NSLog(@"广告曝光回调 %s", __func__);
}

/// 广告点击
- (void)adServerBidClicked {
    NSLog(@"广告点击 %s", __func__);
}

- (void)adServerBidFailedWithError:(NSError *)error description:(NSDictionary *)description{
    [JDStatusBarNotification showWithStatus:@"广告加载失败" dismissAfter:1.5];
    NSLog(@"广告展示失败 %s  error: %@ 详情:%@", __func__, error, description);
}

/// 内部渠道开始加载时调用
- (void)adServerBidSupplierWillLoad:(NSString *)supplierId {
    NSLog(@"内部渠道开始加载 %s  supplierId: %@", __func__, supplierId);

}

/// 点击跳过
- (void)adServerBidFullScreenVideodDidClickSkip {
    NSLog(@"点击了跳过 %s", __func__);
}

/// 广告关闭
- (void)adServerBidDidClose {
    NSLog(@"广告关闭了 %s", __func__);
}

/// 广告播放完成
- (void)adServerBidFullScreenVideoOnAdPlayFinish {
    NSLog(@"广告播放完成 %s", __func__);
}

/// 广告视频缓存完成
- (void)adServerBidFullScreenVideoOnAdVideoCached {
    NSLog(@"广告缓存成功 %s", __func__);
    _isAdLoaded=true;
    [JDStatusBarNotification showWithStatus:@"广告加载成功" dismissAfter:1.5];
    [self loadAdBtn2Action];

}

/// 策略加载成功
- (void)adServerBidOnAdReceived:(NSString *)reqId
{
    NSLog(@"%s 策略id为: %@",__func__ , reqId);
}

@end
