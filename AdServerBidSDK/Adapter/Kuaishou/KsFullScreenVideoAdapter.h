//
//  KsFullScreenVideoAdapter.h
//  AdServerBidSDK
//
//  Created by MS on 2021/4/23.
//

#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import "AdServerBidFullScreenVideoDelegate.h"
NS_ASSUME_NONNULL_BEGIN
@class AdvSupplier;
@class AdServerBidFullScreenVideo;

@interface KsFullScreenVideoAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidFullScreenVideoDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
