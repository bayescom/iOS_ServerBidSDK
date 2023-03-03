//
//  AppDelegate.m
//  AdServerBidSDK
//
//  Created by Cheng455153666 on 02/27/2020.
//  Copyright (c) 2020 Cheng455153666. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

#import <AdServerBidSDK/AdServerBidSplash.h>
#import <AdvSdkConfig.h>

#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

@interface AppDelegate () <AdServerBidSplashDelegate>
@property(strong,nonatomic) AdServerBidSplash *adServerBidSplash;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        
    
#pragma Demo 中有许多内容为开发调试的内容, 仅作为开发者调试自己的账号使用, 不一定会出广告, 建议使用自己的包名和id
    
    // 请现在 plist 文件中配置 NSUserTrackingUsageDescription
    /*
     <key>NSUserTrackingUsageDescription</key>
     <string>该ID将用于向您推送个性化广告</string>
     */
    // 项目需要适配http
    
    /*
     <key>NSAppTransportSecurity</key>
     <dict>
         <key>NSAllowsArbitraryLoads</key>
         <true/>
     </dict>
     */
    // 调试阶段尽量用真机, 以便获取idfa, 如果获取不到idfa, 则打开idfa开关
    // iphone 打开idfa 开关的的过程:设置 -> 隐私 -> 跟踪 -> 允许App请求跟踪
    __block NSString *idfa = @"";
    ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
                idfa = [[manager advertisingIdentifier] UUIDString];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                // do something
                [AdvSdkConfig shareInstance].level = AdvLogLevel_Debug;
            });
        }];
    }else{
        if ([manager isAdvertisingTrackingEnabled]) {
            idfa = [[manager advertisingIdentifier] UUIDString];
        }

    }
    
    return YES;
}


@end
