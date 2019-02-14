//
//  NSString+Limit.m
//  KKPhotoKit
//
//  Created by kkfinger on 2018/6/19.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "NSString+Limit.h"

@implementation NSString(Limit)

- (NSInteger)lengthOfString{
    NSInteger length = 0;
    for (int i = 0; i<[self length]; i++) {
        //截取字符串中的每一个字符
        NSString *s = [self substringWithRange:NSMakeRange(i, 1)];
        if ([self validateChineseChar:s]) {
            length +=2;
        }else{
            length +=1;
        }
    }
    return length;
}

- (NSString *)subStringToIndex:(NSInteger)index{
    NSInteger length = 0;
    NSInteger chineseNum = 0;
    NSInteger zifuNum = 0;
    for (int i = 0; i<[self length]; i++) {
        //截取字符串中的每一个字符
        NSString *s = [self substringWithRange:NSMakeRange(i, 1)];
        if ([self validateChineseChar:s]){
            if (length + 2 > index){
                return [self substringToIndex:chineseNum + zifuNum];
            }
            length +=2;
            chineseNum +=1;
        }else{
            if (length +1 >index){
                return [self substringToIndex:chineseNum + zifuNum];
            }
            length+=1;
            zifuNum +=1;
        }
    }
    return [self substringToIndex:index];
}

//检测中文或者中文符号
- (BOOL)validateChineseChar:(NSString *)string{
    NSString *nameRegEx = @"[\\u0391-\\uFFE5]";
    if (![string isMatchesRegularExp:nameRegEx]) {
        return NO;
    }
    return YES;
}

//检测中文
- (BOOL)validateChinese:(NSString*)string{
    NSString *nameRegEx = @"[\u4e00-\u9fa5]";
    if (![string isMatchesRegularExp:nameRegEx]) {
        return NO;
    }
    return YES;
}

- (BOOL)isMatchesRegularExp:(NSString *)regex {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

@end
