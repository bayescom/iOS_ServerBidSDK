//
//  MercuryNativeExpressAdapter.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidNativeExpressDelegate.h"

@class AdvSupplier;
@class AdServerBidNativeExpress;

NS_ASSUME_NONNULL_BEGIN

@interface MercuryNativeExpressAdapter : NSObject
@property (nonatomic, weak) id<AdServerBidNativeExpressDelegate> delegate;
@property (nonatomic, assign) NSInteger tag;// 标记并行渠道为了找到响应的adapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(AdServerBidNativeExpress *)adspot;

- (void)loadAd;

@end

NS_ASSUME_NONNULL_END
