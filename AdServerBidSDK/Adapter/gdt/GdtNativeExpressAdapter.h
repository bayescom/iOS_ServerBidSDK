//
//  GdtNativeExpressAdapter.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//
#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidNativeExpressDelegate.h"

@class AdvSupplier;
@class AdServerBidNativeExpress;

NS_ASSUME_NONNULL_BEGIN

@interface GdtNativeExpressAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidNativeExpressDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
