//
//  KKImageGalleryCtrl.h
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/5.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKPhotoInfo.h"

@protocol KKImageGalleryCtrlDelegate<NSObject>
- (void)selectImageItem:(KKPhotoInfo *)photoItem isSel:(BOOL)isSel complete:(void(^)(BOOL canOperator,BOOL couldContinueSel,NSInteger curtSelCnt,NSInteger maxLimitCnt))complete;
- (NSInteger)fetchCurrentSelCount;
- (NSArray *)fetchGallerySelectedArray;
@end

@interface KKImageGalleryCtrl : UIViewController
@property(nonatomic,weak)id<KKImageGalleryCtrlDelegate>delegate;
- (instancetype)initWithAlbumId:(NSString *)albumId;
@end
