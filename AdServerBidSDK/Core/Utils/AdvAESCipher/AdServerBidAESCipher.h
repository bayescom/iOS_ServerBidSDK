//
//  AdServerBidAESCipher.h
//  AdServerBidSDK
//
//  Created by MS on 2022/5/5.
//  Copyright © 2022 AdServerBid. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * adServerBidAesEncryptString(NSString *content, NSString *key);
NSString * adServerBidAesDecryptString(NSString *content, NSString *key);

NSData * adServerBidAesEncryptData(NSData *data, NSData *key);
NSData * adServerBidAesDecryptData(NSData *data, NSData *key);

@interface AdServerBidAESCipher : NSObject
//将string转成带密码的data
+ (NSString*)encryptAESData:(NSString*)string Withkey:(NSString * )key ivkey:(NSString * )ivkey;
//将带密码的data转成string
+(NSString*)decryptAESData:(NSString*)data Withkey:(NSString *)key ivkey:(NSString * )ivkey;
@end
