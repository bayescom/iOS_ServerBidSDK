//
//  KsInterstitialAdapter.h
//  AdServerBidSDK
//
//  Created by MS on 2021/4/25.
//

#import <Foundation/Foundation.h>
#import "AdServerBidInterstitialDelegate.h"
#import "AdvBaseAdPosition.h"

NS_ASSUME_NONNULL_BEGIN
@class AdvSupplier;
@class AdServerBidInterstitial;

@interface KsInterstitialAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidInterstitialDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
