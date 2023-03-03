//
//  AdvSupplierModel.m
//  Demo
//
//  Created by CherryKing on 2020/11/18.
//

#import "AdvSupplierModel.h"
#import "AdvLog.h"
#import "AdvModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 以字符串形式返回状态码
NSString * ADVStringFromNAdServerBidSdkSupplierRepoType(AdServerBidSdkSupplierRepoType type) {
    switch (type) {
        case AdServerBidSdkSupplierRepoLoaded:
            return @"AdServerBidSdkSupplierRepoLoaded(发起加载请求上报)";
        case AdServerBidSdkSupplierRepoClicked:
            return @"AdServerBidSdkSupplierRepoClicked(点击上报)";
        case AdServerBidSdkSupplierRepoSucceeded:
            return @"AdServerBidSdkSupplierRepoSucceeded(数据加载成功上报)";
        case AdServerBidSdkSupplierRepoImped:
            return @"AdServerBidSdkSupplierRepoImped(曝光上报)";
        case AdServerBidSdkSupplierRepoFaileded:
            return @"AdServerBidSdkSupplierRepoFaileded(失败上报)";
        default:
            return @"MercuryBaseAdRepoTKEventTypeUnknow(未知类型上报)";
    }
}

#pragma mark - Private model interfaces


@implementation AdvSupplierModel


+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"suppliers" : [AdvSupplier class],
             @"adspot" : [AdvSupplierAdspot class]
    };
}

- (void)dealloc {
    NSLog(@"%s %@", __func__, self);
}

@end

@implementation AdvSupplierAdspot

- (void)dealloc {
    NSLog(@"%s %@", __func__, self);
}

@end

@implementation AdvSupplier
- (void)dealloc {
    NSLog(@"%s %@", __func__, self);
}

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"identifier": @"id",
    };
}

@end

NS_ASSUME_NONNULL_END
