//
//  GdtInterstitialAdapter.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidInterstitialDelegate.h"

@class AdvSupplier;
@class AdServerBidInterstitial;

NS_ASSUME_NONNULL_BEGIN

@interface GdtInterstitialAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidInterstitialDelegate> delegate;
//@property (nonatomic, assign) NSInteger tag;// 标记并行渠道为了找到响应的adapter

//- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(AdServerBidInterstitial *)adspot;

//- (void)loadAd;
//
//- (void)showAd;

@end

NS_ASSUME_NONNULL_END
