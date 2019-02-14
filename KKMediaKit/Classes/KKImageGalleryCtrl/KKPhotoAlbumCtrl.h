//
//  KKPhotoAlbumCtrl.h
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/5.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKPhotoInfo.h"

@protocol KKPhotoAlbumCtrlDelegate<NSObject>
- (void)selectImageItem:(KKPhotoInfo *)info isSel:(BOOL)isSel complete:(void(^)(BOOL canOperator,BOOL couldContinueSel,NSInteger curtSelCnt,NSInteger maxLimitCnt))complete;
- (NSInteger)fetchCurrentSelCount;
- (NSArray *)fetchGallerySelectedArray;
@end

@interface KKPhotoAlbumCtrl : UIViewController
@property(nonatomic,weak)id<KKPhotoAlbumCtrlDelegate>delegate;
@end
