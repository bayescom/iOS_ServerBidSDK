//
//  NSString+Adv.h
//  AdServerBidSDK
//
//  Created by MS on 2023/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Adv)
+ (NSString *)convertToJsonData:(NSDictionary *)dict;

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;


@end

NS_ASSUME_NONNULL_END
