//
//  MercuryInterstitialAdapter.h
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

@interface MercuryInterstitialAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidInterstitialDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
