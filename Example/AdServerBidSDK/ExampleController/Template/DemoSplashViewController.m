//
//  DemoSplashViewController.m
//  AAA
//
//  Created by CherryKing on 2019/11/1.
//  Copyright © 2019 CherryKing. All rights reserved.
//

#import "DemoSplashViewController.h"

#import "DemoUtils.h"
#import <AdServerBidSDK/AdServerBidSplash.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface DemoSplashViewController () <AdServerBidSplashDelegate>
@property(strong,nonatomic) AdServerBidSplash *adServerBidSplash;

@property (nonatomic, strong) NSLock *lock;

@end

@implementation DemoSplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /**
     - 超时时间只需要设置AdServerBidSplash的 timeout属性, 如果在timeout时间内没有广告曝光, 则会强制移除开屏广告,并触发错误回调

     - 每次加载需开屏广告需使用最新的实例, 不要进行本地存储, 或计时器持有的操作

     - 保证在开屏广告生命周期内(包括请求,曝光成功后的展现时间内),不要更换rootVC, 也不要对Window进行操作

     */
    // demo 中的id 为开发环境id
    // 需要id调试的媒体请联系运营同学开通
    self.initDefSubviewsFlag = YES;
    self.adspotIdsArr = @[
//        @{@"addesc": @"mediaId-adspotId", @"adspotId": @"100255-10002619"},
        @{@"addesc": @"SeverBidding开屏测试", @"adspotId": @"000000-10007093"},


//
    ];
    self.btn1Title = @"加载并显示广告";
}

- (void)loadAdBtn1Action {
    if (![self checkAdspotId]) { return; }
    
    if (self.adServerBidSplash) {
        self.adServerBidSplash.delegate = nil;
        self.adServerBidSplash = nil;
    }
    
    // 每次加载广告请 使用新的实例  不要用懒加载, 不要对广告对象进行本地化存储相关的操作
    self.adServerBidSplash = [[AdServerBidSplash alloc] initWithAdspotId:self.adspotId
                                                       customExt:@{} viewController:self];

    self.adServerBidSplash.isUploadSDKVersion = YES;
    self.adServerBidSplash.delegate = self;
    
    /**
      logo图片不应该是仅是一张透明的logo 应该是一张有背景的logo, 且高度等于你设置的logo高度
     
      self.adServerBidSplash.logoImage = [UIImage imageNamed:@"app_logo"];

     */
    
    // 如果想要对logo有特定的布局 则参照 -createLogoImageFromView 方法
    // 建议设置logo 避免某些素材长图不足时屏幕下方留白
    self.adServerBidSplash.logoImage = [self createLogoImageFromView];
    // 设置logo时 该属性要设置为YES
    self.adServerBidSplash.showLogoRequire = YES;

    self.adServerBidSplash.backgroundImage = [UIImage imageNamed:@"LaunchImage_img"];
    // 如果开发者有自己的超时时间限制 那timeout 应该比 开发者 最好比自己的超时时间限制要短
    // 当到达 timeout 后 不出广告adServerBidSplash内部会强制移除广告的不需要开发者手动移除
    self.adServerBidSplash.timeout = 5;//<---- 确保timeout 时长内不对adServerBidSplash进行移除的操作
    [self.adServerBidSplash loadAd];

}


- (UIImage*)createLogoImageFromView

{
    // 在这个方法里你可以随意 定制化logo
   // 300 170
    
    CGFloat width = self.view.frame.size.width;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 120)];
    view.backgroundColor = [UIColor blueColor];
    UIImageView *imageV = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"app_logo"]];
    [view addSubview:imageV];
    imageV.frame = CGRectMake(0, 0, 100 * (300/170.f), 100);
    imageV.center = view.center;
    
//obtain scale
    CGFloat scale = [UIScreen mainScreen].scale;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(view.frame.size.width,
                                                      120), NO,scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    //开始生成图片
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [NSLock new];
    }
    return _lock;
}


// MARK: ======================= AdServerBidSplashDelegate =======================

/// 广告数据拉取成功
- (void)adServerBidUnifiedViewDidLoad {
    NSLog(@"广告数据拉取成功 %s", __func__);
//    [self loadAdBtn1Action];

}

/// 广告曝光成功
- (void)adServerBidExposured {
    NSLog(@"广告曝光成功 %s", __func__);
}

/// 广告加载失败
- (void)adServerBidFailedWithError:(NSError *)error description:(NSDictionary *)description{
    NSLog(@"广告展示失败 %s  error: %@ 详情:%@", __func__, error, description);
    self.adServerBidSplash.delegate = nil;
    self.adServerBidSplash = nil;

}
/// 内部渠道开始加载时调用
- (void)adServerBidSupplierWillLoad:(NSString *)supplierId {
    NSLog(@"内部渠道开始加载 %s  supplierId: %@", __func__, supplierId);

}
/// 广告点击
- (void)adServerBidClicked {
    NSLog(@"广告点击 %s", __func__);
}

/// 广告关闭
- (void)adServerBidDidClose {
    NSLog(@"广告关闭了 %s", __func__);
    self.adServerBidSplash.delegate = nil;
    self.adServerBidSplash = nil;

}

- (void)dealloc {
    NSLog(@"%s",__func__);
    self.adServerBidSplash.delegate = nil;
    self.adServerBidSplash = nil;
}

/// 广告倒计时结束
- (void)adServerBidSplashOnAdCountdownToZero {
    NSLog(@"广告倒计时结束 %s", __func__);
}

/// 点击了跳过
- (void)adServerBidSplashOnAdSkipClicked {
    NSLog(@"点击了跳过 %s", __func__);
}

// 策略请求成功
- (void)adServerBidOnAdReceived:(NSString *)reqId
{
    NSLog(@"%s 策略id为: %@",__func__ , reqId);
}

@end
