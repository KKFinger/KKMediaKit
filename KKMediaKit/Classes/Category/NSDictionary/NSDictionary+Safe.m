//
//  NSDictionary+Safe.m
//  KKPhotoKit
//
//  Created by kkfinger on 2018/9/21.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "NSDictionary+Safe.h"

@implementation NSDictionary(Safe)

- (id)safeObjectForKey:(id)aKey{
    if(!aKey){
        return nil ;
    }
    return [self objectForKey:aKey];
}

@end

@implementation NSMutableDictionary(Safe)

- (void)safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey{
    if(!anObject){
        return ;
    }
    if(!aKey){
        return ;
    }
    [self setObject:anObject forKey:aKey];
}

- (void)safeRemoveObjectForKey:(id)aKey{
    if(!aKey){
        return ;
    }
    [self removeObjectForKey:aKey];
}

@end
