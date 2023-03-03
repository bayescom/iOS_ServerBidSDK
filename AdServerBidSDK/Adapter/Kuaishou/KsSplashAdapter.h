//
//  KsSplashAdapter.h
//  AdServerBidSDK
//
//  Created by MS on 2021/4/20.
//
#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidSplashDelegate.h"
NS_ASSUME_NONNULL_BEGIN
@class AdvSupplier;
@class AdServerBidSplash;

@interface KsSplashAdapter : AdvBaseAdPosition

@property (nonatomic, weak) id<AdServerBidSplashDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
