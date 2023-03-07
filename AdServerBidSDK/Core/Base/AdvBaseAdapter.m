//
//  AdvBaseAdapter.m
//  Demo
//
//  Created by CherryKing on 2020/11/20.
//

#import "AdvBaseAdapter.h"
#import "AdvSupplierManager.h"
#import "AdServerBidSupplierDelegate.h"
#import "AdvLog.h"
#import "AdvSdkConfig.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "AdServerBidAESCipher.h"

//# if __has_include(<ABUAdSDK/ABUAdSDK.h>)
//#import <ABUAdSDK/ABUAdSDK.h>
//#else
//#import <Ads-Mediation-CN/ABUAdSDK.h>
//#endif

@interface AdvBaseAdapter ()  <AdvSupplierManagerDelegate, AdServerBidSupplierDelegate>
@property (nonatomic, strong) AdvSupplierManager *mgr;

@property (nonatomic, weak) id<AdServerBidSupplierDelegate> baseDelegate;


@end

@implementation AdvBaseAdapter

-  (instancetype)initWithMediaId:(NSString *)mediaId
                        adspotId:(NSString *)adspotid {
    return [self initWithMediaId:mediaId adspotId:adspotid customExt:nil];
}

- (instancetype)initWithMediaId:(NSString *)mediaId
                       adspotId:(NSString *)adspotid
                      customExt:(NSDictionary *)ext {
    if (self = [super init]) {
        _mediaId = mediaId;
        _adspotid = adspotid;
        _ext = [ext mutableCopy];
        _mgr = [AdvSupplierManager manager];
        _mgr.delegate = self;
        _baseDelegate = self;
        if (!_arrParallelSupplier) {
            _arrParallelSupplier = [NSMutableArray array];
        }

        if (!_errorDescriptions) {
            _errorDescriptions = [NSMutableDictionary dictionary];
        }

    }
    return self;
}

- (void)loadAd {
    if (_isUploadSDKVersion) {
        [self setSDKVersion];
    }
    [_mgr loadDataWithMediaId:_mediaId adspotId:_adspotid customExt:_ext];
}

/// 加载策略
- (void)loadAdWithSupplierModel:(AdvSupplierModel *)model {
    
}

- (void)loadNextSupplierIfHas {
    
}

- (void)reportWithType:(AdServerBidSdkSupplierRepoType)repoType supplier:(AdvSupplier *)supplier error:(NSError *)error {
//    NSLog(@"|||--- %@ %ld %@",supplier.sdktag, (long)supplier.identifier.integerValue, supplier);
    [_mgr reportWithType:repoType supplier:supplier error:error];
     
    
    // 搜集各渠道的错误信息
    if (error) {
        [self collectErrorWithSupplier:supplier error:error];
    }

    // 搜集各个渠道的token信息
    if (repoType == AdServerBidSdkSupplierRepoBiddingToken) {
        [_mgr collectBiddingTokenWithSupplier:supplier];
    }
    
    // 胜出渠道的信息
    if (repoType == AdServerBidSdkSupplierRepoBiddingWinInfo) {
        [_mgr requestWinSupplier:supplier];
    }

    // 如果并发渠道失败了 要通知mananger那边 _inwaterfallcount -1
    if (repoType == AdServerBidSdkSupplierRepoFaileded && supplier.isParallel) {
        [_mgr inParallelWithErrorSupplier:supplier];
    }
}

// 开始bidding
- (void)advManagerBiddingActionWithSuppliers:(NSMutableArray<AdvSupplier *> *)suppliers {
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(adServerBidBaseAdapterBiddingAction:)]) {
        [self.baseDelegate adServerBidBaseAdapterBiddingAction:suppliers];
    }
}

// bidding结束
- (void)advManagerBiddingEndWithWinSupplier:(AdvSupplier *)winSupplier {
    // 抛出去 下个版本会在每个广告位的 adServerBidBaseAdapterBiddingEndWithWinSupplier 里 执行GroMore的逻辑
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(adServerBidBaseAdapterBiddingEndWithWinSupplier:)]) {
        [self.baseDelegate adServerBidBaseAdapterBiddingEndWithWinSupplier:winSupplier];
    }
}

- (void)collectErrorWithSupplier:(AdvSupplier *)supplier error:(NSError *)error {
    // key: 渠道名-优先级
    if (error) {
        NSString *key = [NSString stringWithFormat:@"%ld", supplier.identifier.integerValue];
        [self.errorDescriptions setObject:error forKey:key];
    }
}

- (void)deallocAdapter {
    // 该方法为AdServerBidSDK 内部调用 开发者不要在外部手动调用 想要释放 直接将广告对象置为nil即可
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    
    _baseDelegate = nil;
    _mgr.delegate = nil;
    [_arrParallelSupplier removeAllObjects];
    _arrParallelSupplier = nil;
    _mgr = nil;
}

//- (void)setDefaultAdvSupplierWithMediaId:(NSString *)mediaId
//                                adspotId:(NSString *)adspotid
//                                mediaKey:(NSString *)mediakey
//                                   sdkId:(nonnull NSString *)sdkid {
//    [self.mgr setDefaultAdvSupplierWithMediaId:mediaId adspotId:adspotid mediaKey:mediakey sdkId:sdkid];
//}

// MARK: ======================= AdvSupplierManagerDelegate =======================
/// 加载策略Model成功
- (void)advSupplierManagerLoadSuccess:(AdvSupplierModel *)model {
    if ([_baseDelegate respondsToSelector:@selector(adServerBidBaseAdapterLoadSuccess:)]) {
        [_baseDelegate adServerBidBaseAdapterLoadSuccess:model];
    }
}

/// 加载策略Model失败
- (void)advSupplierManagerLoadError:(NSError *)error {
    if ([_baseDelegate respondsToSelector:@selector(adServerBidBaseAdapterLoadError:)]) {
        [_baseDelegate adServerBidBaseAdapterLoadError:error];
    }
}

// 返回了倍业SDK信息
- (void)advSupplierLoadMercurySupplier:(AdvSupplierAdspot *)mercuryAdspot {
    
    // MercurySDK
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ADV_LEVEL_INFO_LOG(@"初始化MercurySDK");
        Class cls = NSClassFromString(@"MercuryConfigManager");
        NSLog(@"%@ %@",mercuryAdspot.appid, mercuryAdspot.appkey);
        [cls performSelector:@selector(setAppID:mediaKey:) withObject:mercuryAdspot.appid withObject:mercuryAdspot.appkey];
        
        NSString *ua = [self.ext objectForKey:AdServerBidSDKUaKey];
        if (ua) {
            NSString *uaEncrypt = adServerBidAesEncryptString(ua, AdServerBidSDKSecretKey);
            
            [cls performSelector:@selector(setDefaultUserAgent:) withObject:uaEncrypt];
        }
    });
    
}

/// 返回下一个渠道的参数
- (void)advSupplierLoadSuppluer:(nullable AdvSupplier *)supplier error:(nullable NSError *)error {

    
    // 初始化渠道参数
    NSString *clsName = @"";
    if ([supplier.identifier isEqualToString:SDK_ID_GDT]) {
        clsName = @"GDTSDKConfig";
    } else if ([supplier.identifier isEqualToString:SDK_ID_CSJ]) {
        clsName = @"BUAdSDKManager";
    } else if ([supplier.identifier isEqualToString:SDK_ID_KS]) {
        clsName = @"KSAdSDKManager";
    }
    
    

    if ([supplier.identifier isEqualToString:SDK_ID_GDT]) {
        // 广点通SDK
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            [NSClassFromString(clsName) performSelector:@selector(registerAppId:) withObject:supplier.sdk_app_id];
        });
        
    } else if ([supplier.identifier isEqualToString:SDK_ID_CSJ]) {
        // 穿山甲SDK
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
//            [NSClassFromString(clsName) performSelector:@selector(setAppID:) withObject:supplier.sdk_app_id];
            [NSClassFromString(clsName) performSelector:@selector(setAppID:) withObject:@"5000546"];
            
        });
    } else if ([supplier.identifier isEqualToString:SDK_ID_KS]) {
        // 快手
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [NSClassFromString(clsName) performSelector:@selector(setAppId:) withObject:supplier.sdk_app_id];
        });

    } else {
        
    }

//    NSLog(@"---> %@", [NSThread currentThread]);
    // 加载渠道
    if ([_baseDelegate respondsToSelector:@selector(adServerBidBaseAdapterLoadSuppluer:error:)]) {
        [_baseDelegate adServerBidBaseAdapterLoadSuppluer:supplier error:error];
    }
}

- (void)setSDKVersion {
    [self setGdtSDKVersion];
    [self setCsjSDKVersion];
    [self setMerSDKVersion];
    [self setKsSDKVersion];
}

- (void)setGdtSDKVersion {
    id cls = NSClassFromString(@"GDTSDKConfig");
    NSString *gdtVersion = [cls performSelector:@selector(sdkVersion)];
    
    [self setSDKVersionForKey:@"gdt_v" version:gdtVersion];
}

- (void)setCsjSDKVersion {
    id cls = NSClassFromString(@"BUAdSDKManager");
    NSString *csjVersion = [cls performSelector:@selector(SDKVersion)];
    
    [self setSDKVersionForKey:@"csj_v" version:csjVersion];
}

- (void)setMerSDKVersion {
    id cls = NSClassFromString(@"MercuryConfigManager");
    NSString *merVersion = [cls performSelector:@selector(sdkVersion)];

    [self setSDKVersionForKey:@"mry_v" version:merVersion];
}

- (void)setKsSDKVersion {
    id cls = NSClassFromString(@"KSAdSDKManager");
    NSString *ksVersion = [cls performSelector:@selector(SDKVersion)];
    
    [self setSDKVersionForKey:@"ks_v" version:ksVersion];
}





- (void)setSDKVersionForKey:(NSString *)key version:(NSString *)version {
    if (version) {
        [_ext setValue:version forKey:key];
    }
}

// 查找一下 容器里有没有并行的渠道
- (id)adapterInParallelsWithSupplier:(AdvSupplier *)supplier {
    id adapterT;
    for (NSInteger i = 0 ; i < _arrParallelSupplier.count; i++) {
        
        id temp = _arrParallelSupplier[i];
        NSInteger tag = ((NSInteger (*)(id, SEL))objc_msgSend)((id)temp, @selector(tag));
        if (tag == supplier.identifier.integerValue) {
            adapterT = temp;
        }
    }
    return adapterT;
}

- (BOOL)isEmptyString:(NSString *)string{
       if(string == nil) {
            return YES;
        }
        if (string == NULL) {
            return YES;
        }
        if ([string isKindOfClass:[NSNull class]]) {
            return YES;
        }
        if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]==0) {
            return YES;
        }
    return NO;
}


- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    [self deallocAdapter];
}

@end
