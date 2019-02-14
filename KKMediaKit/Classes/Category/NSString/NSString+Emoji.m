//
//  NSString+Emoji.m
//  KKPhotoKit
//
//  Created by kkfinger on 2018/9/7.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "NSString+Emoji.h"

@implementation NSString(Emoji)

- (NSString *)encodeEmoji{
    NSString *uniStr = [NSString stringWithUTF8String:[self UTF8String]];
    NSData *uniData = [uniStr dataUsingEncoding:NSNonLossyASCIIStringEncoding];
    return [[NSString alloc] initWithData:uniData encoding:NSUTF8StringEncoding] ;
}

- (NSString *)decodeEmoji{
    const char *jsonString = [self UTF8String];
    NSData *jsonData = [NSData dataWithBytes:jsonString length:strlen(jsonString)];
    return [[NSString alloc] initWithData:jsonData encoding:NSNonLossyASCIIStringEncoding];
}

@end
