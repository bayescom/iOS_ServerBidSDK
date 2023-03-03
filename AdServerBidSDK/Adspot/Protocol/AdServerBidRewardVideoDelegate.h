//
//  AdServerBidRewardVideoProtocol.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/9.
//  Copyright © 2020 bayescom. All rights reserved.
//

#ifndef AdServerBidRewardVideoProtocol_h
#define AdServerBidRewardVideoProtocol_h
#import "AdServerBidBaseDelegate.h"
@protocol AdServerBidRewardVideoDelegate <AdServerBidBaseDelegate>
@optional

/// 广告视频缓存完成
- (void)adServerBidRewardVideoOnAdVideoCached;

/// 广告视频播放完成
- (void)adServerBidRewardVideoAdDidPlayFinish;

/// 广告到达激励时间
- (void)adServerBidRewardVideoAdDidRewardEffective:(BOOL)isReward;

@end

#endif
