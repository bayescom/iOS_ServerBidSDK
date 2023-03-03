//
//  KsRewardVideoAdapter.h
//  AdServerBidSDK
//
//  Created by MS on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import "AdServerBidRewardVideoDelegate.h"
#import "AdvBaseAdPosition.h"
NS_ASSUME_NONNULL_BEGIN
@class AdvSupplier;
@class AdServerBidRewardVideo;

@interface KsRewardVideoAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidRewardVideoDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
