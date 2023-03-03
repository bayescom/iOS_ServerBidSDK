//
//  GdtRewardVideoAdapter.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidRewardVideoDelegate.h"

@class AdvSupplier;
@class AdServerBidRewardVideo;

NS_ASSUME_NONNULL_BEGIN

@interface GdtRewardVideoAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidRewardVideoDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
