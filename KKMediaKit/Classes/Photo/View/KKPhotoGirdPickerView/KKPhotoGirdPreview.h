//
//  KKQuestionImagePreview.h
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/17.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKPhotoInfo.h"
#import "KKDragableBaseView.h"

@interface KKQuestionImagePreview : KKDragableBaseView
@property(nonatomic,assign)NSInteger selCount;
@property(nonatomic,copy)void(^deleteImageBlock)(KKPhotoInfo *photoItem,NSInteger deleteIndex,void(^deleteCallback)(NSInteger selCount,NSInteger maxSelCount,NSArray<KKPhotoInfo *> *array));
- (instancetype)initWithImageArray:(NSArray<KKPhotoInfo *> *)imageArray selIndex:(NSInteger)selIndex selCount:(NSInteger)selCount;
@end
