//
//  AdServerBidFullScreenVideoDelegate.h
//  AdServerBidSDKDev
//
//  Created by CherryKing on 2020/4/13.
//  Copyright © 2020 bayescom. All rights reserved.
//

#ifndef AdServerBidFullScreenVideoDelegate_h
#define AdServerBidFullScreenVideoDelegate_h
#import "AdServerBidBaseDelegate.h"
@protocol AdServerBidFullScreenVideoDelegate <AdServerBidBaseDelegate>
@optional
/// 视频播放完成
- (void)adServerBidFullScreenVideoOnAdPlayFinish;
- (void)adServerBidFullScreenVideodDidClickSkip;
- (void)adServerBidFullScreenVideoOnAdVideoCached;


@end

#endif
