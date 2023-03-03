//
//  CsjInterstitialProAdapter.h
//  AdServerBidSDK
//
//  Created by MS on 2021/5/20.
//


#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import "AdServerBidInterstitialDelegate.h"

@class AdvSupplier;
@class AdServerBidInterstitial;


NS_ASSUME_NONNULL_BEGIN

@interface CsjInterstitialProAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidInterstitialDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
