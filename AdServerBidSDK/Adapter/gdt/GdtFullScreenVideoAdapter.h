//
//  GdtFullScreenVideoAdapter.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/13.
//  Copyright © 2020 bayescom. All rights reserved.
//

#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdServerBidFullScreenVideoDelegate.h"

@class AdvSupplier;
@class AdServerBidFullScreenVideo;

NS_ASSUME_NONNULL_BEGIN

@interface GdtFullScreenVideoAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidFullScreenVideoDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
