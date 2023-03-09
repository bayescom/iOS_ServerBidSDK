//
//  AdServerBidSplash.m
//  Demo
//
//  Created by CherryKing on 2020/11/19.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "AdServerBidSplash.h"
#import "AdServerBidSupplierDelegate.h"
#import "AdvSupplierModel.h"
#import "UIApplication+Adv.h"
#import "AdvLog.h"
#import "AdvError.h"
#import "AdvUploadTKUtil.h"
@interface AdServerBidSplash ()
@property (nonatomic, strong) id adapter;

@property (nonatomic, strong) UIImageView *bgImgV;

@property (nonatomic, assign) NSInteger timeout_stamp;
@property (nonatomic, strong) CADisplayLink *timeoutCheckTimer;
@property (nonatomic, copy) NSString *reqId;
@property (nonatomic, strong) NSNumber *isGMBidding;
@property (nonatomic, strong, readwrite) NSDictionary *extParameter;
@end

@implementation AdServerBidSplash

- (instancetype)initWithAdspotId:(NSString *)adspotid viewController:(nonnull UIViewController *)viewController {
    return [self initWithAdspotId:adspotid customExt:nil viewController:viewController];
}

- (instancetype)initWithAdspotId:(NSString *)adspotid customExt:(NSDictionary *)ext viewController:(UIViewController *)viewController {
    ADV_LEVEL_INFO_LOG(@"==================== 初始化开屏广告, id: %@====================", adspotid);
    ext = [ext mutableCopy];
    if (!ext) {
        ext = [NSMutableDictionary dictionary];
    }
    [ext setValue:AdvSdkTypeAdNameSplash forKey: AdvSdkTypeAdName];
    _extParameter = [ext mutableCopy];
    if (self = [super initWithMediaId:@"" adspotId:adspotid customExt:ext]) {
        _viewController = viewController;
    }
    return self;
}

- (NSDictionary *)extParameter {
    return _extParameter;
}

- (void)loadAd {
    // 占位图
    [[UIApplication sharedApplication].adv_getCurrentWindow addSubview:self.bgImgV];
        
    if (_timeout <= 0) { _timeout = 60; }
    // 记录过期的时间
    _timeout_stamp = ([[NSDate date] timeIntervalSince1970] + _timeout)*1000;
    // 开启定时器监听过期
    [_timeoutCheckTimer invalidate];

    _timeoutCheckTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeoutCheckTimerAction)];
    [_timeoutCheckTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [super loadAd];
}

- (void)reportWithType:(AdServerBidSdkSupplierRepoType)repoType supplier:(nonnull AdvSupplier *)supplier error:(nonnull NSError *)error {
    [super reportWithType:repoType supplier:supplier error:error];
    if (repoType == AdServerBidSdkSupplierRepoImped) {
//        ADVLog(@"曝光成功 计时器清零");
        [_timeoutCheckTimer invalidate];
        _timeoutCheckTimer = nil;
        [_bgImgV removeFromSuperview];
        _bgImgV = nil;
    }
}


/// Override
- (void)deallocSelf {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    [_bgImgV removeFromSuperview];
    _bgImgV = nil;
    [_timeoutCheckTimer invalidate];
    _timeoutCheckTimer = nil;
    _timeout_stamp = 0;

}

- (void)deallocDelegate:(BOOL)execute {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    if([_delegate respondsToSelector:@selector(adServerBidFailedWithError:description:)] && execute) {
        [_delegate adServerBidFailedWithError:[AdvError errorWithCode:AdvErrorCode_115].toNSError description:[self.errorDescriptions copy]];
        [_adapter performSelector:@selector(deallocAdapter)];
//        [self uploadTimeOutError];
        [self deallocAdapter];
    }
    _delegate = nil;
}

// 无论怎样到达超时时间时  都必须移除开屏广告
- (void)timeoutCheckTimerAction {
    if ([[NSDate date] timeIntervalSince1970]*1000 > _timeout_stamp) {
        [self deallocDelegate:YES];
        [self deallocSelf];
    }
}

// 返回策略id
- (void)adServerBidOnAdReceivedWithReqId:(NSString *)reqId
{
    self.reqId = reqId;
    if ([_delegate respondsToSelector:@selector(adServerBidOnAdReceived:)]) {
        [_delegate adServerBidOnAdReceived:reqId];
    }
}

// MARK: ======================= AdServerBidSupplierDelegate =======================
/// 加载策略Model成功
- (void)adServerBidBaseAdapterLoadSuccess:(nonnull AdvSupplierModel *)model {
    // 返回策略id
    [self adServerBidOnAdReceivedWithReqId:model.reqid];
}

/// 加载策略Model失败
- (void)adServerBidBaseAdapterLoadError:(nullable NSError *)error {
    if ([_delegate respondsToSelector:@selector(adServerBidFailedWithError:description:)]) {
        [_delegate adServerBidFailedWithError:error description:[self.errorDescriptions copy]];
    }
    [self deallocSelf];
    [self deallocDelegate:NO];
}

// 开始bidding
- (void)adServerBidBaseAdapterBiddingAction:(NSMutableArray <AdvSupplier *> *_Nullable)suppliers {
//    if (self.delegate && [self.delegate respondsToSelector:@selector(adServerBidBiddingAction)]) {
//        [self.delegate adServerBidBiddingAction];
//    }
}

// bidding结束
- (void)adServerBidBaseAdapterBiddingEndWithWinSupplier:(AdvSupplier *_Nonnull)supplier {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adServerBidBiddingEndWithPrice:)]) {

        [self.delegate adServerBidBiddingEndWithPrice:0];
    }
}



- (void)adServerBidBaseAdapterLoadSuppluer:(nullable AdvSupplier *)supplier error:(nullable NSError *)error {
    // 返回渠道有问题 则不用再执行下面的渠道了
    if (error) {
        ADV_LEVEL_ERROR_LOG(@"%@", error);
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(adServerBidFailedWithError:description:)]) {
            [self.delegate adServerBidFailedWithError:error description:[self.errorDescriptions copy]];
        }
        [self deallocSelf];
        [self deallocDelegate:NO];
        return;
    }

    if (supplier.isParallel == NO) {// 只有当串行队列执行该渠道时 才会回调用代理 并行渠道不调用该代理
        // 开始加载渠道前通知调用者
        if ([self.delegate respondsToSelector:@selector(adServerBidSupplierWillLoad:)]) {
            [self.delegate adServerBidSupplierWillLoad:supplier.identifier];
        }
    }

    // 根据渠道id自定义初始化
    NSString *clsName = @"";
    if ([supplier.identifier isEqualToString:SDK_ID_GDT]) {
        clsName = @"GdtSplashAdapter";
    } else if ([supplier.identifier isEqualToString:SDK_ID_CSJ]) {
        clsName = @"CsjSplashAdapter";
    } else if ([supplier.identifier isEqualToString:SDK_ID_MERCURY]) {
        clsName = @"MercurySplashAdapter";
    } else if ([supplier.identifier isEqualToString:SDK_ID_KS]) {
        clsName = @"KsSplashAdapter";
    }
    
    
    
    // 请求超时了
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970]*1000;
    if ((_timeout_stamp > 0) && (now+500 > _timeout_stamp)
        && !(supplier.state == AdServerBidSdkSupplierStateSuccess || supplier.state == AdServerBidSdkSupplierStateFailed)) {
        // 1. 串行时如果前面的渠道加载时间过长 导致后面的渠道加载时间不足(还剩0.5s) 则默认下面的渠道无法加载成功, 直接清空view 结束此次广告加载流程
        // 2. 并行时,如果有结果了(成功或者失败) 则不应移除
//        ADVLog(@"总时长到了, 该清空了");
        [self deallocSelf]; //清空view 重置解释器
        [self deallocDelegate:YES];// 向外回调错误
    } else {
        if (NSClassFromString(clsName)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            // 1. 如果是并行渠道, 则生成一个adapter并标记渠道
            // 2. 将生成的adapter 存储到容器中保持其广告加载的流程
            // 3. 等到串行队列执行到该渠道的时候 直接载入这个adapter的加载流程里
            if (supplier.isParallel) {
                id adapter = ((id (*)(id, SEL, id, id))objc_msgSend)((id)[NSClassFromString(clsName) alloc], @selector(initWithSupplier:adspot:), supplier, self);
                // 标记当前的adapter 为了让当串行执行到的时候 获取这个adapter
                // 没有设置代理
//                ADVLog(@"并行: %@", adapter);
                ((void (*)(id, SEL, NSInteger))objc_msgSend)((id)adapter, @selector(setTag:), supplier.identifier.integerValue);
                ((void (*)(id, SEL))objc_msgSend)((id)adapter, @selector(loadAd));

                if (adapter) {
                    // 存储并行的adapter
                    [self.arrParallelSupplier addObject:adapter];
                }

            } else {
                // supplier.state 的意义是标记并行渠道
                // 如果串行队列 执行到的渠道是并行渠道时 则依然要修改其超时时间
                if (supplier.state != AdServerBidSdkSupplierStateSuccess && supplier.state != AdServerBidSdkSupplierStateFailed) {
                    
                } else {
                    supplier.timeout = (_timeout_stamp - now) >= 5000 ? 5000 : (_timeout_stamp - now);
                }
                // 1. 先移除上一个失败的渠道
                // 2. 先看看当前执行的串行渠道 是不是之前的并行渠道
                // 3. 如果不是之前的并行渠道 则为 其他串行渠道
                // 4. 如果是之前的并行渠道, 直接载入
                
                [_adapter performSelector:@selector(deallocAdapter)];
                _adapter = [self adapterInParallelsWithSupplier:supplier];
                if (!_adapter) {
                    _adapter = ((id (*)(id, SEL, id, id))objc_msgSend)((id)[NSClassFromString(clsName) alloc], @selector(initWithSupplier:adspot:), supplier, self);
                }
//                    ADVLog(@"串行 %@ %ld", _adapter, (long)[_adapter tag]);
                // 设置代理
                ((void (*)(id, SEL, id))objc_msgSend)((id)_adapter, @selector(setDelegate:), _delegate);
                ((void (*)(id, SEL))objc_msgSend)((id)_adapter, @selector(loadAd));
                
            }
#pragma clang diagnostic pop
        } else {
            NSString *msg = [NSString stringWithFormat:@"%@ 不存在", clsName];
            ADV_LEVEL_INFO_LOG(@"%@", msg);
            [self loadNextSupplierIfHas];
        }
    }
}

// MARK: ======================= get =======================
- (UIViewController *)viewController {
    if (_viewController) {
        return _viewController;
    } else {
        return [UIApplication sharedApplication].adv_getCurrentWindow.rootViewController;
    }
}

- (UIImageView *)bgImgV {
    if (!_bgImgV) {
        _bgImgV = [[UIImageView alloc] initWithImage:_backgroundImage];
    }
    _bgImgV.frame = [UIScreen mainScreen].bounds;
    _bgImgV.userInteractionEnabled = YES;
    return _bgImgV;
}

- (void)showAd {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    dispatch_async(dispatch_get_main_queue(), ^{
       // UI更新代码
        ((void (*)(id, SEL))objc_msgSend)((id)_adapter, @selector(showAd));

    });


#pragma clang diagnostic pop
}


- (void)gmShowAd {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    dispatch_async(dispatch_get_main_queue(), ^{
       // UI更新代码
        ((void (*)(id, SEL))objc_msgSend)((id)_adapter, @selector(gmShowAd));

    });


#pragma clang diagnostic pop

}
- (void)uploadTimeOutError {
    NSMutableDictionary *paramsM = [NSMutableDictionary dictionary];
    
    if (self.mediaId) {
        [paramsM setObject:self.mediaId forKey:@"mediaid"];
    }
    if (self.adspotid) {
        [paramsM setObject:self.adspotid forKey:@"adspotid"];
    }
    if (self.reqId) {
        [paramsM setObject:self.reqId forKey:@"reqId"];
    }
    
    [paramsM setObject:@"开屏广告超时,被强制关闭" forKey:@"msg"];
    [paramsM setObject:@(1001) forKey:@"code"];

    [AdvUploadTKUtil.new reportEventWithParams:paramsM];
    

}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
    ((void (*)(id, SEL))objc_msgSend)((id)_adapter, @selector(deallocAdapter));
    _adapter = nil;
}

@end
