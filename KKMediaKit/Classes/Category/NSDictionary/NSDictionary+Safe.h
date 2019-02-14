//
//  NSDictionary+Safe.h
//  KKPhotoKit
//
//  Created by kkfinger on 2018/9/21.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface NSDictionary<__covariant KeyType, __covariant ObjectType>(Safe)
- (id)safeObjectForKey:(id)aKey;
@end


@interface NSMutableDictionary<KeyType, ObjectType> (Safe)
- (void)safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)safeRemoveObjectForKey:(id)aKey;
@end
