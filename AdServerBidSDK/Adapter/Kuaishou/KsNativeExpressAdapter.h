//
//  KsNativeExpressAdapter.h
//  AdServerBidSDK
//
//  Created by MS on 2021/4/23.
//

#import "AdvBaseAdPosition.h"
#import <Foundation/Foundation.h>
#import "AdServerBidNativeExpressDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class AdvSupplier;
@class AdServerBidNativeExpress;

@interface KsNativeExpressAdapter : AdvBaseAdPosition
@property (nonatomic, weak) id<AdServerBidNativeExpressDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
