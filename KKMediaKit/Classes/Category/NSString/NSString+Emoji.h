//
//  NSString+Emoji.h
//  KKPhotoKit
//
//  Created by kkfinger on 2018/9/7.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Emoji)
- (NSString *)encodeEmoji;
- (NSString *)decodeEmoji;
@end
