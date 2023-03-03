//
//  AdServerBidBanner.m
//  AdServerBidSDKExample
//
//  Created by CherryKing on 2020/4/7.
//  Copyright © 2020 Mercury. All rights reserved.
//

#import "AdServerBidBanner.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "AdvLog.h"

@interface AdServerBidBanner ()
@property (nonatomic, strong) id adapter;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) UIViewController *controller;

@end

@implementation AdServerBidBanner

- (instancetype)initWithAdspotId:(NSString *)adspotid
                     adContainer:(UIView *)adContainer
                  viewController:(nonnull UIViewController *)viewController {
    return [self initWithAdspotId:adspotid adContainer:adContainer customExt:nil viewController:viewController];
}

- (instancetype)initWithAdspotId:(NSString *)adspotid
                     adContainer:(UIView *)adContainer
                       customExt:(NSDictionary * _Nonnull)ext
                  viewController:(nonnull UIViewController *)viewController {
    if (self = [super initWithMediaId:@"" adspotId:adspotid customExt:ext]) {
        _adContainer = adContainer;
        _viewController = viewController;
        _refreshInterval = 30;
    }
    return self;
}

// 返回策略id
- (void)adServerBidOnAdReceivedWithReqId:(NSString *)reqId
{
    if ([_delegate respondsToSelector:@selector(adServerBidOnAdReceived:)]) {
        [_delegate adServerBidOnAdReceived:reqId];
    }
}

// MARK: ======================= AdServerBidSupplierDelegate =======================
/// 加载策略Model成功
- (void)adServerBidBaseAdapterLoadSuccess:(nonnull AdvSupplierModel *)model {
//    if ([_delegate respondsToSelector:@selector(adServerBidSplashOnAdReceived)]) {
//        [_delegate adServerBidSplashOnAdReceived];
//    }
    [self adServerBidOnAdReceivedWithReqId:model.reqid];
}

/// 加载策略Model失败
- (void)adServerBidBaseAdapterLoadError:(nullable NSError *)error {
    if ([_delegate respondsToSelector:@selector(adServerBidFailedWithError:description:)]) {
        [_delegate adServerBidFailedWithError:error description:[self.errorDescriptions copy]];
    }
}

/// 返回下一个渠道的参数
- (void)adServerBidBaseAdapterLoadSuppluer:(nullable AdvSupplier *)supplier error:(nullable NSError *)error {
    // 返回渠道有问题 则不用再执行下面的渠道了
    if (error) {
        // 错误回调只调用一次
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(adServerBidFailedWithError:description:)]) {
            [self.delegate adServerBidFailedWithError:error description:[self.errorDescriptions copy]];
        }
        return;
    }
    
    // 开始加载渠道前通知调用者
    if ([self.delegate respondsToSelector:@selector(adServerBidSupplierWillLoad:)]) {
        [self.delegate adServerBidSupplierWillLoad:supplier.identifier];
    }

    // 根据渠道id自定义初始化
    NSString *clsName = @"";
    if ([supplier.identifier isEqualToString:SDK_ID_GDT]) {
        clsName = @"GdtBannerAdapter";
    } else if ([supplier.identifier isEqualToString:SDK_ID_CSJ]) {
        clsName = @"CsjBannerAdapter";
    } else if ([supplier.identifier isEqualToString:SDK_ID_MERCURY]) {
        clsName = @"MercuryBannerAdapter";
    } else if ([supplier.identifier isEqualToString:SDK_ID_BAIDU]) {
        clsName = @"BdBannerAdapter";
    }
    
        
    if (NSClassFromString(clsName)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        _adapter = ((id (*)(id, SEL, id, id))objc_msgSend)((id)[NSClassFromString(clsName) alloc], @selector(initWithSupplier:adspot:), supplier, self);
        ((void (*)(id, SEL, id))objc_msgSend)((id)_adapter, @selector(setDelegate:), _delegate);
        ((void (*)(id, SEL))objc_msgSend)((id)_adapter, @selector(loadAd));
#pragma clang diagnostic pop
    } else {
        NSString *msg = [NSString stringWithFormat:@"%@ 不存在", clsName];
        //        ADVLog(@"%@", msg);
        [self loadNextSupplierIfHas];
    }
}


@end
