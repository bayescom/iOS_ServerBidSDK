//
//  AdvLog.m
//  Example
//
//  Created by CherryKing on 2019/11/5.
//  Copyright © 2019 CherryKing. All rights reserved.
//

#import "AdvLog.h"
#import "AdvSdkConfig.h"
#import <CommonCrypto/CommonDigest.h>

NSString *const LOG_LEVEL_NONE_SCHEME   = @"0";
NSString *const LOG_LEVEL_FATAL_SCHEME  = @"ADV_LEVE_FATAL";
NSString *const LOG_LEVEL_ERROR_SCHEME  = @"ADV_LEVEL_ERROR";
NSString *const LOG_LEVEL_WARING_SCHEME = @"ADV_LEVE_WARNING";
NSString *const LOG_LEVEL_INFO_SCHEME   = @"ADV_LEVE_INFO";
NSString *const LOG_LEVEL_DEBUG_SCHEME  = @"ADV_LEVE_DEBUG";

@interface NSString (MD5)

- (NSString *)md5;

@end

@implementation NSString (MD5)

- (NSString *)md5 {
    const char* character = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(character, strlen(character), result);
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x",result[i]];
    }
    return md5String;
}

@end


@implementation AdvLog

+ (void)customLogWithFunction:(const char *)function lineNumber:(int)lineNumber formatString:(NSString *)formatString {
    
}

+ (void)customLogWithFunction:(const char *)function lineNumber:(int)lineNumber formatString:(NSString *)formatString level:(AdvLogLevel)level{
    
    
    NSString *scheme = @"";
    
    if (level == 1) {
        scheme = LOG_LEVEL_FATAL_SCHEME;
    } else if (level == 2) {
        
        scheme = LOG_LEVEL_ERROR_SCHEME;
    } else if (level == 3) {
        
        scheme = LOG_LEVEL_WARING_SCHEME;
    } else if (level == 4) {
        
        scheme = LOG_LEVEL_INFO_SCHEME;
    } else if (level == 5) {
        
        scheme = LOG_LEVEL_DEBUG_SCHEME;
    }
    
    if (level <= [AdvSdkConfig shareInstance].level) {
        [self customLogWithFunctionAction:function lineNumber:lineNumber formatString:formatString scheme:scheme];
    }
    
    
}

+ (void)customLogWithFunctionAction:(const char *)function lineNumber:(int)lineNumber formatString:(NSString *)formatString scheme:(NSString *)scheme {
    if ([formatString containsString:@"[JSON]"]) {
        formatString = [formatString stringByReplacingOccurrencesOfString:@" " withString:@""];
        formatString = [formatString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        formatString = [formatString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    }
    NSLog(@"\n%s[line:%d][%@] %@", function, lineNumber, scheme, formatString);
    
}

+ (void)logJsonData:(NSData *)data {
//    NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//    NSString *md5 = [[res description] md5];
//    [[NSUserDefaults standardUserDefaults] setObject:data forKey:md5];
    
//    ADVLog(@"[JSON][-%@-]", md5);
//    ADV_LEVEL_INFO_LOG(@"%@", res);
}

@end
