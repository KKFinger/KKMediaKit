//
//  NSString+Limit.h
//  KKPhotoKit
//
//  Created by kkfinger on 2018/6/19.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString(Limit)
- (NSInteger)lengthOfString;
- (NSString *)subStringToIndex:(NSInteger)index;
@end
