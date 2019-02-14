//
//  KKPhotoInfo.m
//  KKPhotoKit
//
//  Created by finger on 2017/10/14.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKPhotoInfo.h"

@implementation KKPhotoInfo

- (instancetype)init{
    self = [super init];
    if(self){
        self.isNewAdd = NO ;
        self.isGif = NO ;
        self.photoType = KKPhotoInfoTypeGallery;
        self.uploadState = KKImageUploadStateNone;
    }
    return self;
}

@end
