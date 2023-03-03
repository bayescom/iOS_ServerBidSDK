//
//  CsjBannerAdapter.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidBannerDelegate.h"

@class AdvSupplier;
@class AdServerBidBanner;

NS_ASSUME_NONNULL_BEGIN

@interface CsjBannerAdapter : AdvBaseAdPosition

@property (nonatomic, weak) id<AdServerBidBannerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
