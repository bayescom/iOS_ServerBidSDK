//
//  GdtSplashAdapter.h
//  AdServerBidSDKExample
//
//  Created by CherryKing on 2020/4/8.
//  Copyright © 2020 Gdt. All rights reserved.
//

#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidSplashDelegate.h"

@class AdvSupplier;
@class AdServerBidSplash;

NS_ASSUME_NONNULL_BEGIN

@interface GdtSplashAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidSplashDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
