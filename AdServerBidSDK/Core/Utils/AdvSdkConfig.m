//
//  AdvSdkConfig.m
//  adServerBidlib
//
//  Created by allen on 2019/9/12.
//  Copyright © 2019 Bayescom. All rights reserved.
//

#import "AdvSdkConfig.h"
#import "AdvLog.h"
@interface AdvSdkConfig ()
@property (nonatomic, strong) NSDictionary *config;

@end

@implementation AdvSdkConfig
NSString *const AdServerBidSdkAPIVersion = @"1.0";
NSString *const AdServerBidSdkVersion = @"1.0.0.0";
NSString *const AdServerBidSdkRequestUrl = @"https://cruiser.bayescom.cn/voyager";
NSString *const AdServerBidReportDataUrl = @"http://cruiser.bayescom.cn/native";
NSString *const AdServerBidSdkRequestMockUrl = @"https://mock.yonyoucloud.com/mock/2650/api/v3/eleven";
NSString *const AdServerBidSdkEventUrl = @"https://cruiser.bayescom.cn/sdkevent";
NSString *const SDK_ID_MERCURY =@"1000";// 此id只有本地使用 为何服务端确认
NSString *const SDK_ID_GDT=@"1002";
NSString *const SDK_ID_CSJ=@"1001";
NSString *const SDK_ID_KS =@"1003";
NSString *const SDK_ID_BAIDU=@"4";
NSString *const SDK_ID_TANX=@"7";
NSString *const SDK_ID_BIDDING=@"8";

//NSString * const AdvSdkConfigCAID = @"kMercuryConfigCAIDKey";
//NSString * const AdvSdkConfigCAIDPublicKey = @"kMercuryConfigCAIDPublicKey-Key";
//NSString * const AdvSdkConfigCAIDPublicForApiKey = @"kMercuryConfigCAIDPublicForApiKey-Key";
//NSString * const AdvSdkConfigCAIDDevId = @"kMercuryConfigCAIDDevIdKey";


int const ADVANCE_RECEIVED = 0;
int const ADVANCE_ERROR = 1;

// MARK: ======================= 穿山甲配置 Key =======================
NSString * const AdvSdkConfigBUAppID = @"AdvSdkConfigBUAppID";

NSString * const AdvSdkConfigBULogLevel = @"AdvSdkConfigBULogLevel";

NSInteger const AdvSdkConfigBULogLevelNone  = 0;  //BUAdSDKLogLevelNone;
NSInteger const AdvSdkConfigBULogLevelError = 1;  //BUAdSDKLogLevelError;
NSInteger const AdvSdkConfigBULogLevelDebug = 2;  //BUAdSDKLogLevelDebug;

NSString * const AdvSdkConfigBUIsPaidApp = @"AdvSdkConfigBUIsPaidApp";
NSString * const AdvSdkConfigBUCoppa = @"AdvSdkConfigBUCoppa";
NSString * const AdvSdkConfigBUUserKeywords = @"AdvSdkConfigBUUserKeywords";
NSString * const AdvSdkConfigBUUserExtData = @"AdvSdkConfigBUUserExtData";

NSString * const AdvSdkConfigBUOfflineType = @"AdvSdkConfigBUOfflineType";
NSInteger const AdvSdkConfigBUOfflineTypeNone       = 0; //BUOfflineTypeNone;
NSInteger const AdvSdkConfigBUOfflineTypeProtocol   = 1; //BUOfflineTypeProtocol;
NSInteger const AdvSdkConfigBUOfflineTypeWebview    = 2; //BUOfflineTypeWebview;
// MARK: ======================= Mercury配置 Key =======================
NSString * const AdvSdkConfigMercuryAppID = @"AdvSdkConfigMercuryAppID";
NSString * const AdvSdkConfigMercuryMediaKey = @"AdvSdkConfigMercuryMediaKey";
NSString * const AdvSdkConfigMercuryOpenDebug = @"AdvSdkConfigMercuryOpenDebug";
NSString * const AdvSdkConfigMercuryOpenRreload = @"AdvSdkConfigMercuryOpenRreload";
// MARK: ======================= 广点通配置 Key =======================
NSString * const AdvSdkConfigGDTEnableGPS = @"AdvSdkConfigGDTEnableGPS";
NSString * const AdvSdkConfigGDTChannel = @"AdvSdkConfigGDTChannel";
NSString * const AdvSdkConfigGDTSdkSrc = @"AdvSdkConfigGDTSdkSrc";
NSString * const AdvSdkConfigGDTSdkType = @"AdvSdkConfigGDTSdkType";

// MARK: ======================= 广告位类型名称 =======================
NSString * const AdvSdkTypeAdName = @"ADNAME";
NSString * const AdvSdkTypeAdNameSplash = @"SPLASH_AD";
NSString * const AdvSdkTypeAdNameBanner = @"BANNER_AD";
NSString * const AdvSdkTypeAdNameInterstitial = @"INTERSTAITIAL_AD";
NSString * const AdvSdkTypeAdNameFullScreenVideo = @"FULLSCREENVIDEO_AD";
NSString * const AdvSdkTypeAdNameNativeExpress = @"NATIVEEXPRESS_AD";
NSString * const AdvSdkTypeAdNameRewardVideo = @"REWARDVIDEO_AD";

// MARK: ======================= NSUserDefaultsKeys =======================

NSString * const AdServerBidSDKModelKey = @"AdServerBidSDKModelKey";
NSString * const AdServerBidSDKIdfaKey = @"AdServerBidSDKIdfaKey";
NSString * const AdServerBidSDKIdfvKey = @"AdServerBidSDKIdfvKey";
NSString * const AdServerBidSDKUaKey = @"AdServerBidSDKUaKey";
NSString * const AdServerBidSDKCarrierKey = @"AdServerBidSDKCarrierKey";
NSString * const AdServerBidSDKNetworkKey = @"AdServerBidSDKNetworkKey";
//timeKeys
NSString * const AdServerBidSDKTimeOutForeverKey = @"AdServerBidSDKTimeOutForeverKey";
NSString * const AdServerBidSDKOneMonthKey = @"AdServerBidSDKOneMonthKey";
NSString * const AdServerBidSDKHourKey = @"AdServerBidSDKHourKey";
NSString * const AdServerBidSDKSecretKey = @"bayescom1000000w";

NSString * const MercuryLogoShowTypeKey = @"MercuryLogoShowTypeKey";
NSString * const MercuryLogoShowBlankGapKey = @"MercuryLogoShowBlankGapKey";


static AdvSdkConfig *instance = nil;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    //dispatch_once （If called simultaneously from multiple threads, this function waits synchronously until the block has completed. 由官方解释，该函数是线程安全的）
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
        instance.isAdTrack = YES;
    });
    return instance;
}

+ (NSString *)sdkVersion {
    return AdServerBidSdkVersion;
}

//保证从-alloc-init和-new方法返回的对象是由shareInstance返回的
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [AdvSdkConfig shareInstance];
}

//保证从copy获取的对象是由shareInstance返回的
- (id)copyWithZone:(struct _NSZone *)zone {
    return [AdvSdkConfig shareInstance];
}

//保证从mutableCopy获取的对象是由shareInstance返回的
- (id)mutableCopyWithZone:(struct _NSZone *)zone {
    return [AdvSdkConfig shareInstance];
}


- (void)setLevel:(AdvLogLevel)level {
    _level = level;
}

//- (void)setCaidConfig:(NSDictionary *)caidConfig {
//    _caidConfig = caidConfig;
//}
@end
