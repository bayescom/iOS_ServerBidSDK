//
//  AdvSupplierManager.m
//  Demo
//
//  Created by CherryKing on 2020/11/18.
//

#import "AdvSupplierManager.h"
#import "AdvDeviceInfoUtil.h"
#import "AdvSdkConfig.h"
#import "AdvSupplierModel.h"
#import "AdvError.h"
#import "AdvLog.h"
#import "AdvModel.h"
#import "AdvAdsportInfoUtil.h"
#import "AdvUploadTKUtil.h"
#import <objc/runtime.h>
#import <objc/message.h>
@interface AdvSupplierManager ()
{
    NSInteger _saveTokenCount;
    NSInteger _waterfallMinPrice;

}
@property (nonatomic, strong) AdvSupplierModel *model;

// 可执行渠道
@property (nonatomic, strong) NSMutableArray<AdvSupplier *> *supplierM;

/// 媒体id
@property (nonatomic, copy) NSString *mediaId;
/// 广告位id
@property (nonatomic, copy) NSString *adspotId;
/// 自定义拓展字段
@property (nonatomic, strong) NSDictionary *ext;

/// 是否是走的本地的渠道
@property (nonatomic, assign) BOOL isLoadLocalSupplier;


@property (nonatomic, strong) AdvUploadTKUtil *tkUploadTool;

@property (nonatomic, strong) NSMutableArray *arrayWaterfall;
@property (nonatomic, strong) NSMutableArray *arrayHeadBidding;


/// 计时器检测bidding时间
@property (nonatomic, strong) CADisplayLink *timeoutCheckTimer;
@property (nonatomic, strong) NSMutableArray *tokenInfos;
@property (nonatomic, strong) AdvSupplier *mercurySupplier;
/// bidding截止时间戳
@property (nonatomic, assign) NSInteger timeout_stamp;

@end

@implementation AdvSupplierManager

+ (instancetype)manager {
    AdvSupplierManager *mgr = [AdvSupplierManager new];
    return mgr;
}

/**
 * 同步数据
 * 如果本地存在有效数据，直接加载本地数据
 * 数据不存在则同步数据
 */
- (void)loadDataWithMediaId:(NSString *)mediaId
                   adspotId:(NSString *)adspotId
                  customExt:(NSDictionary * _Nonnull)ext {
    _mediaId = mediaId;
    _adspotId = adspotId;
    _tkUploadTool = [[AdvUploadTKUtil alloc] init];
    _ext = [ext mutableCopy];
    _arrayHeadBidding = [NSMutableArray array];
    _arrayWaterfall = [NSMutableArray array];
    _tokenInfos = [NSMutableArray array];
    _saveTokenCount = 0;
//    [MIZombieSniffer installSniffer];
    
    // model不存在
    if (!_model) {
        ADV_LEVEL_INFO_LOG(@"本地策略不可用，拉取线上策略");
        _isLoadLocalSupplier = NO;
        [self fetchData:NO];
    } else {
        _isLoadLocalSupplier = YES;
        ADV_LEVEL_INFO_LOG(@"执行本地策略");
        _supplierM = [_model.suppliers mutableCopy];
        if ([_delegate respondsToSelector:@selector(advSupplierManagerLoadSuccess:)]) {
            [_delegate advSupplierManagerLoadSuccess:self.model];
        }
        // 开始执行策略
        [self loadBiddingSupplier];
    }
}


- (void)loadBiddingSupplier {
    if (_model == nil) {
        ADV_LEVEL_ERROR_LOG(@"策略请求失败");
        if ([_delegate respondsToSelector:@selector(advSupplierManagerLoadError:)]) {
            [_delegate advSupplierManagerLoadError:[AdvError errorWithCode:AdvErrorCode_102].toNSError];
        }


        return;
    }
    
    // 回调倍业SDK 信息 初始化
    if (_model.adspot) {
        if (_delegate && [_delegate respondsToSelector:@selector(advSupplierLoadMercurySupplier:)]) {
            [_delegate advSupplierLoadMercurySupplier:_model.adspot];
        }
    }
    
    // 执行并发请求token
    __weak typeof(self) _self = self;
    [_supplierM enumerateObjectsUsingBlock:^(AdvSupplier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(_self) self = _self;
        obj.isParallel = YES;
        [self notCPTLoadNextSuppluer:obj error:nil];
        
    }];
}

// bidding渠道按价格排序
- (void)_sortSuppliersByPrice:(NSMutableArray <AdvSupplier *> *)suppliers {
    
    // 停止检测时间戳
    [self deallocTimer];
    

}

/// 非 CPT 执行下个渠道
- (void)notCPTLoadNextSuppluer:(nullable AdvSupplier *)supplier error:(nullable NSError *)error {
    // 非包天 选择渠道执行都失败
    if (supplier == nil || _supplierM.count <= 0) {
        // 抛异常
        if ([_delegate respondsToSelector:@selector(advSupplierLoadSuppluer:error:)]) {
            [_delegate advSupplierLoadSuppluer:nil error:[AdvError errorWithCode:AdvErrorCode_114].toNSError];
        }
        return;
    }
    
    
    if (supplier.isParallel) {
        
    } else {
        [_supplierM removeObject:supplier];
    }
    
    ADV_LEVEL_INFO_LOG(@"当前执行的渠道:%@ 是否并行:%d 优先级:%ld", supplier, supplier.isParallel, (long)supplier.identifier.integerValue);

    
    // 如果成功或者失败 就意味着 该并行渠道有结果了, 所以不需要改变状态了
    // 正在加载中的时候 表明并行渠道正在加载 只要等待就可以了所以也不需要改变状态
    if (supplier.state == AdServerBidSdkSupplierStateFailed || supplier.state == AdServerBidSdkSupplierStateSuccess || supplier.state == AdServerBidSdkSupplierStateInPull) {
        // 只有并行的渠道才有可能走到这里 因为只有并行渠道才会 有成功失败请求中的状态 串行渠道 执行的时候已经从_supplierM移除了
        
        
    } else {
        // 不是准备就绪的状态 就是改为InHand
        if (supplier.state != AdServerBidSdkSupplierStateReady) {
            supplier.state = AdServerBidSdkSupplierStateInHand;
        }
        [self reportWithType:AdServerBidSdkSupplierRepoLoaded supplier:supplier error:nil];
    }
    
    if ([_delegate respondsToSelector:@selector(advSupplierLoadSuppluer:error:)]) {
        [_delegate advSupplierLoadSuppluer:supplier error:error];
    }
    ADV_LEVEL_INFO_LOG(@"执行过后执行的渠道:%@ 是否并行:%d 优先级:%ld", supplier, supplier.isParallel, (long)supplier.identifier.integerValue);

}


// MARK: ======================= Net Work =======================
/// 拉取线上数据 如果是仅仅储存 不会触发任何回调，仅存储策略信息
- (void)fetchData:(BOOL)saveOnly {
    NSMutableDictionary *deviceInfo = [[AdvDeviceInfoUtil sharedInstance] getDeviceInfoWithMediaId:_mediaId adspotId:_adspotId];
    
    if (self.ext) {
        
        // 如果是缓存渠道 请求的时候要标记一下
        if (_isLoadLocalSupplier) {
            [self.ext setValue:@"1" forKey:@"cache_effect"];
        }
        
        [deviceInfo setValue:self.ext forKey:@"ext"];
        
        ADV_LEVEL_INFO_LOG(@"自定义扩展字段 ext : %@", self.ext);
    }
    
    ADV_LEVEL_INFO_LOG(@"请求参数 %@", deviceInfo);
    NSLog(@"%@", [self jsonStringCompactFormatForDictionary:deviceInfo]);
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:deviceInfo options:NSJSONWritingPrettyPrinted error:&parseError];
    NSURL *url = [NSURL URLWithString:AdServerBidSdkRequestUrl];
//    NSURL *url = [NSURL URLWithString:AdServerBidSdkRequestMockUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.fetchTime];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = jsonData;
    request.HTTPMethod = @"POST";
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    
    
    self.tkUploadTool.serverTime = [[NSDate date] timeIntervalSince1970]*1000;

    
    ADV_LEVEL_INFO_LOG(@"开始请求时间戳: %f", [[NSDate date] timeIntervalSince1970]);
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [sharedSession dataTaskWithRequest:request
                                                      completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;//第一层
        __weak typeof(self) weakSelf2 = strongSelf;
        if (weakSelf2 == nil){return;}
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf2 = weakSelf2;//第二层
            if (strongSelf2 == nil){return;}
            ADV_LEVEL_INFO_LOG(@"请求完成时间戳: %f", [[NSDate date] timeIntervalSince1970]);
//            ADVTRACK(self.mediaId, self.adspotId, AdvTrackEventCase_getAction);
//            [MIZombieSniffer installSniffer];
            [strongSelf2 doResultData:data response:response error:error saveOnly:saveOnly];
        });
    }];
    [dataTask resume];
}

// 搜集token等相关信息
- (void)collectBiddingTokenWithSupplier:(AdvSupplier *)supplier {
    _saveTokenCount++;
    NSMutableDictionary *dicTemp = [NSMutableDictionary dictionary];
    if ([supplier.identifier isEqualToString:SDK_ID_GDT]) {
//        if (supplier.buyerId) {
//            [dicTemp setObject:supplier.buyerId forKey:@"buyer_id"];
//        }
//
//        if (supplier.sdkInfo) {
//            [dicTemp setObject:supplier.sdkInfo forKey:@"sdk_info"];
//        }
//
//        [dicTemp setObject:SDK_ID_GDT forKey:@"sdk_id"];
//        [_tokenInfos addObject:dicTemp];
    } else if ([supplier.identifier isEqualToString:SDK_ID_CSJ]) {
        
        if (supplier.token) {
            [dicTemp setObject:supplier.token forKey:@"sdk_token"];
        }

        [dicTemp setObject:SDK_ID_CSJ forKey:@"sdk_id"];
        [_tokenInfos addObject:dicTemp];
    } else if ([supplier.identifier isEqualToString:SDK_ID_KS]) {
        
//        NSLog(@"kstoken: %@",supplier.ksToken);
//        if (supplier.ksToken) {
//            [dicTemp setObject:supplier.ksToken forKey:@"sdkToken"];
//        }
//        [dicTemp setObject:SDK_ID_KS forKey:@"sdk_id"];
//        [_tokenInfos addObject:dicTemp];
    }

    if (_saveTokenCount == _model.suppliers.count) {
        [self loadMercurySupplier:_tokenInfos];
    }
}

- (void)loadMercurySupplier:(NSMutableArray *)arrayInfos {
        
    self.mercurySupplier = [[AdvSupplier alloc] init];
    self.mercurySupplier.identifier = SDK_ID_MERCURY;
    self.mercurySupplier.sdkBiddingInfo = arrayInfos;
    self.mercurySupplier.sdk_adspot_id = _model.adspot.adspotid;
    self.mercurySupplier.isParallel = YES;

    [self notCPTLoadNextSuppluer:self.mercurySupplier error:nil];
}

// 请求获胜渠道的广告
- (void)requestWinSupplier:(AdvSupplier *)supplier {
    
    if ([supplier.winSupplierId isEqualToString:SDK_ID_MERCURY]) {
        self.mercurySupplier.winSupplierInfo = supplier.winSupplierInfo;
        self.mercurySupplier.isParallel = NO;
        self.mercurySupplier.state = AdServerBidSdkSupplierStateReady;
        [self notCPTLoadNextSuppluer: self.mercurySupplier error:nil];

    } else {
        __weak typeof(self) _self = self;
        [_supplierM enumerateObjectsUsingBlock:^(AdvSupplier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(_self) self = _self;

            // 根据id找到对应的胜出渠道
            if ([obj.identifier isEqualToString:supplier.winSupplierId]) {
                
                obj.winSupplierInfo = supplier.winSupplierInfo;
                obj.isParallel = NO;
                obj.state = AdServerBidSdkSupplierStateReady;
                [self notCPTLoadNextSuppluer:obj error:nil];
                *stop = YES;
            }
        }];
    }
}

- (void)inParallelWithErrorSupplier:(AdvSupplier *)errorSupplier {
    
}


- (NSString *)jsonStringCompactFormatForDictionary:(NSDictionary *)dicJson {

    if (![dicJson isKindOfClass:[NSDictionary class]] || ![NSJSONSerialization isValidJSONObject:dicJson]) {

        return nil;

    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicJson options:0 error:nil];

    NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return strJson;

}


/// 处理返回的数据
- (void)doResultData:(NSData * )data response:(NSURLResponse *)response error:(NSError *)error saveOnly:(BOOL)saveOnly {
    if (error) {
        // error
        if (saveOnly && [_delegate respondsToSelector:@selector(advSupplierManagerLoadError:)]) {
            [_delegate advSupplierManagerLoadError:[AdvError errorWithCode:AdvErrorCode_101 obj:error].toNSError];
        }
        return;
    }
    
    if (!data || !response) {
        // no result
        if (!saveOnly && [_delegate respondsToSelector:@selector(advSupplierManagerLoadError:)]) {
            [_delegate advSupplierManagerLoadError:[AdvError errorWithCode:AdvErrorCode_102].toNSError];
        }
        return;
    }
    
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
    if (httpResp.statusCode != 200) {
        // code no statusCode
        if (!saveOnly && [_delegate respondsToSelector:@selector(advSupplierManagerLoadError:)]) {
            [_delegate advSupplierManagerLoadError:[AdvError errorWithCode:AdvErrorCode_103 obj:error].toNSError];
        }
        
        
        // 默认走打底
        ADV_LEVEL_ERROR_LOG(@"statusCode != 200, 策略返回出错");
        //        [self doBaseSupplierIfHas];
        return;
    }
    
    NSError *parseErr = nil;
    AdvSupplierModel *a_model = [AdvSupplierModel adv_modelWithJSON:data];
    NSLog(@"[JSON]%@", [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
    if (parseErr || !a_model) {
        // parse error
        if (!saveOnly && [_delegate respondsToSelector:@selector(advSupplierManagerLoadError:)]) {
            [_delegate advSupplierManagerLoadError:[AdvError errorWithCode:AdvErrorCode_104 obj:parseErr].toNSError];
        }
        return;
        ADV_LEVEL_ERROR_LOG(@"策略解析出错");
    }
    
    if (a_model.code != 200) {
        // result code not 200
        // 策略失败回调和渠道失败回调统一, 当策略失败 但是打底渠道成功时 则不抛错误
        if (!saveOnly && [_delegate respondsToSelector:@selector(advSupplierManagerLoadError:)]) {
            [_delegate advSupplierManagerLoadError:[AdvError errorWithCode:AdvErrorCode_105 obj:error].toNSError];
        }
        
        ADV_LEVEL_ERROR_LOG(@"statusCode != 200, 策略返回出错");
        return;
    }
    
    _model = a_model;
    _supplierM = [_model.suppliers mutableCopy];
    
    if ([_delegate respondsToSelector:@selector(advSupplierManagerLoadSuccess:)]) {
        [_delegate advSupplierManagerLoadSuccess:_model];
    }

    // 现在全都走新逻辑
    [self loadBiddingSupplier];
}



// MARK: ======================= 上报 =======================
- (void)reportWithType:(AdServerBidSdkSupplierRepoType)repoType supplier:(AdvSupplier *)supplier error:(nonnull NSError *)error{
    NSArray<NSString *> *uploadArr = nil;
    /// 按照类型判断上报地址
    if (repoType == AdServerBidSdkSupplierRepoLoaded) {
        uploadArr = [self.tkUploadTool loadedtkUrlWithArr:supplier.loadedtk];
    } else if (repoType == AdServerBidSdkSupplierRepoClicked) {
        uploadArr =  supplier.clicktk;
    } else if (repoType == AdServerBidSdkSupplierRepoSucceeded) {

        uploadArr =  [self.tkUploadTool succeedtkUrlWithArr:supplier.succeedtk price:(supplier.supplierPrice == 0) ? supplier.sdk_price : supplier.supplierPrice];
        // 曝光成功 更新本地策略
        if (_isLoadLocalSupplier) {
            ADV_LEVEL_INFO_LOG(@"曝光成功 此次使用本地缓存 更新本地策略");
            [self fetchData:YES];
        }
    } else if (repoType == AdServerBidSdkSupplierRepoImped) {
        uploadArr =  [self.tkUploadTool imptkUrlWithArr:supplier.imptk price:(supplier.supplierPrice == 0) ? supplier.sdk_price : supplier.supplierPrice];
    } else if (repoType == AdServerBidSdkSupplierRepoFaileded) {
        
        
        uploadArr =  [self.tkUploadTool failedtkUrlWithArr:supplier.failedtk error:error];
        
    } else if (repoType == AdServerBidSdkSupplierRepoGMBidding) {
        uploadArr =  [self.tkUploadTool imptkUrlWithArr:supplier.biddingtk price:(supplier.supplierPrice == 0) ? supplier.sdk_price : supplier.supplierPrice];
    }
    
    if (!uploadArr || uploadArr.count <= 0) {
        // TODO: 上报地址不存在
        return;
    }
    // 执行上报请求
    [self.tkUploadTool reportWithUploadArr:uploadArr error:error];
    ADV_LEVEL_INFO_LOG(@"%@ = 上报(impid: %@)", ADVStringFromNAdServerBidSdkSupplierRepoType(repoType), supplier.identifier);
}

- (AdvUploadTKUtil *)tkUploadTool {
    if (!_tkUploadTool) {
        _tkUploadTool = [AdvUploadTKUtil new];
    }
    return _tkUploadTool;
}

// MARK: ======================= get =======================
- (NSTimeInterval)fetchTime {
    if (_fetchTime <= 0) {
        _fetchTime = 5;
    }
    return _fetchTime;
}

- (void)deallocTimer {
    [_timeoutCheckTimer invalidate];
    _timeoutCheckTimer = nil;
    _timeout_stamp = 0;
}

- (void)dealloc
{
    ADV_LEVEL_INFO_LOG(@"%s %@", __func__, self);
    [self deallocTimer];
    _tkUploadTool = nil;
    
    [_arrayHeadBidding removeAllObjects];
    _arrayHeadBidding = nil;
    
    [_arrayWaterfall removeAllObjects];
    _arrayWaterfall = nil;

    [_supplierM removeAllObjects];
    _supplierM = nil;
    _model = nil;
    NSLog(@"==>%@",_model.suppliers);

}
@end
