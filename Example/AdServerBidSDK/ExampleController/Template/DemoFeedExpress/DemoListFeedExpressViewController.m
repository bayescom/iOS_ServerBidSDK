//
//  DemoListFeedExpressViewController.m
//  Example
//
//  Created by CherryKing on 2019/11/21.
//  Copyright © 2019 CherryKing. All rights reserved.
//

#import "DemoListFeedExpressViewController.h"
#import "CellBuilder.h"
#import "BYExamCellModel.h"

#import "DemoUtils.h"
#import <AdServerBidSDK/AdServerBidNativeExpress.h>
#import <AdServerBidSDK/AdServerBidNativeExpressView.h>
@interface DemoListFeedExpressViewController () <UITableViewDelegate, UITableViewDataSource, AdServerBidNativeExpressDelegate>
@property (strong, nonatomic) UITableView *tableView;

@property(strong,nonatomic) AdServerBidNativeExpress *adServerBidFeed;
@property (nonatomic, strong) NSMutableArray *dataArrM;
@property (nonatomic, strong) NSMutableArray *arrViewsM;

@end

@implementation DemoListFeedExpressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"信息流";
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"splitnativeexpresscell"];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"nativeexpresscell"];
    [_tableView registerClass:[ExamTableViewCell class] forCellReuseIdentifier:@"ExamTableViewCell"];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    
    [self loadBtnAction:nil];
}

- (void)loadBtnAction:(id)sender {
    _dataArrM = [NSMutableArray arrayWithArray:[CellBuilder dataFromJsonFile:@"cell01"]];
//    _adServerBidFeed = [[AdServerBidNativeExpress alloc] initWithAdspotId:@"11111112" viewController:self adSize:CGSizeMake(self.view.bounds.size.width, 300)];
//    _adServerBidFeed = [[AdServerBidNativeExpress alloc] initWithAdspotId:self.adspotId viewController:self adSize:CGSizeMake(self.view.bounds.size.width, 300)];
    if (self.adServerBidFeed) {
        self.adServerBidFeed = nil;
    }
    // adSize 高度设置0
    _adServerBidFeed = [[AdServerBidNativeExpress alloc] initWithAdspotId:self.adspotId customExt:self.ext viewController:self adSize:CGSizeMake(self.view.bounds.size.width, 0)];

    _adServerBidFeed.delegate = self;
    [_adServerBidFeed loadAd];
}

// MARK: ======================= AdServerBidNativeExpressDelegate =======================
/// 广告数据拉取成功
- (void)adServerBidNativeExpressOnAdLoadSuccess:(NSArray<AdServerBidNativeExpressView *> *)views {
    NSLog(@"广告拉取成功 %s", __func__);
    self.arrViewsM = [views mutableCopy];
    for (NSInteger i = 0; i < self.arrViewsM.count; i++) {
        AdServerBidNativeExpressView *view = self.arrViewsM[i];
        [view render];
        [_dataArrM insertObject:self.arrViewsM[i] atIndex:1];
        NSLog(@"=11===> %@  %@",view, view.expressView);
    }
    [self.tableView reloadData];

}


/// 广告曝光
- (void)adServerBidNativeExpressOnAdShow:(AdServerBidNativeExpressView *)adView {
    NSLog(@"广告曝光 %s", __func__);
}

/// 广告点击
- (void)adServerBidNativeExpressOnAdClicked:(AdServerBidNativeExpressView *)adView {
    NSLog(@"广告点击 %s", __func__);
}

/// 广告渲染成功
/// 注意和广告数据拉取成功的区别  广告数据拉取成功, 但是渲染可能会失败
/// 广告加载失败 是广点通 穿山甲 mercury 在拉取广告的时候就全部失败了
/// 该回调的含义是: 比如: 广点通拉取广告成功了并返回了一组view  但是其中某个view的渲染失败了
/// 该回调会触发多次
- (void)adServerBidNativeExpressOnAdRenderSuccess:(AdServerBidNativeExpressView *)adView {
    NSLog(@"广告渲染成功 %s %@", __func__, adView);
    [self.tableView reloadData];
}

/// 广告渲染失败
/// 注意和广告加载失败的区别  广告数据拉取成功, 但是渲染可能会失败
/// 广告加载失败 是广点通 穿山甲 mercury 在拉取广告的时候就全部失败了
/// 该回调的含义是: 比如: 广点通拉取广告成功了并返回了一组view  但是其中某个view的渲染失败了
/// 该回调会触发多次
- (void)adServerBidNativeExpressOnAdRenderFail:(AdServerBidNativeExpressView *)adView {
    NSLog(@"广告渲染失败 %s %@", __func__, adView);
    [_dataArrM removeObject: adView];
    [self.tableView reloadData];
}

/// 广告加载失败
/// 该回调只会触发一次
- (void)adServerBidFailedWithError:(NSError *)error description:(NSDictionary *)description{
    NSLog(@"广告展示失败 %s  error: %@ 详情:%@", __func__, error, description);

}

/// 内部渠道开始加载时调用
- (void)adServerBidSupplierWillLoad:(NSString *)supplierId {
    NSLog(@"内部渠道开始加载 %s  supplierId: %@", __func__, supplierId);

}

/// 加载策略成功
- (void)adServerBidOnAdReceived:(NSString *)reqId
{
    NSLog(@"%s 策略id为: %@",__func__ , reqId);
}

/// 广告被关闭
- (void)adServerBidNativeExpressOnAdClosed:(AdServerBidNativeExpressView *)adView {
    //需要从tableview中删除
    NSLog(@"广告关闭 %s", __func__);
    [_dataArrM removeObject: adView];
    [self.tableView reloadData];
    self.adServerBidFeed = nil;
}

// MARK: ======================= UITableViewDelegate, UITableViewDataSource =======================

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return _expressAdViews.count*2;
//    return 2;
    return _dataArrM.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_dataArrM[indexPath.row] isKindOfClass:[BYExamCellModelElement class]]) {
        return ((BYExamCellModelElement *)_dataArrM[indexPath.row]).cellh;
    } else {
        
        AdServerBidNativeExpressView *adView = _dataArrM[indexPath.row];
        
        
        UIView *view = [adView expressView];
        NSLog(@"====> %@  %@",adView, view);
        CGFloat height = view.frame.size.height;
        if ([adView.identifier isEqualToString:SDK_ID_TANX]) {
            return height + 10;
        } else {
            return height;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ([_dataArrM[indexPath.row] isKindOfClass:[BYExamCellModelElement class]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ExamTableViewCell"];
        ((ExamTableViewCell *)cell).item = _dataArrM[indexPath.row];
        return cell;
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nativeexpresscell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        UIView *subView = (UIView *)[cell.contentView viewWithTag:1000];
        if ([subView superview]) {
            [subView removeFromSuperview];
        }
        AdServerBidNativeExpressView *adView = _dataArrM[indexPath.row];
        
        
        UIView *view = [adView expressView];

        view.tag = 1000;
        [cell.contentView addSubview:view];
        cell.accessibilityIdentifier = @"nativeTemp_ad";
        
        // 展示广告的cell高度 -tableView:heightForRowAtIndexPath:
        if ([adView.identifier isEqualToString:SDK_ID_TANX]) { // tanx 的广告不带padding 需要自己调节
            [view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(cell.contentView);
                make.left.equalTo(@(10));
                make.right.equalTo(@(-10));
                make.bottom.equalTo(@(10));
            }];
        }
        return cell;
    }
}
- (void)dealloc {
    NSLog(@"%s", __func__);
    self.adServerBidFeed = nil;
}

@end


