//
//  KKImageThumbCell.h
//  KKPhotoKit
//
//  Created by finger on 2017/10/22.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKPhotoInfo.h"

typedef NS_ENUM(NSInteger, KKImageThumbCellType){
    KKImageThumbCellTypeDelete,
    KKImageThumbCellTypeSelect,
    KKImageThumbCellTypeEdit
} ;

@class KKImageThumbCell;
@protocol KKImageThumbCellDelegate <NSObject>
@optional
- (void)deleteImage:(KKImageThumbCell *)cell photoItem:(KKPhotoInfo *)item;
- (void)selectImage:(KKImageThumbCell *)cell photoItem:(KKPhotoInfo *)item;
- (void)showPreviewView:(KKImageThumbCell *)cell;
@end

@interface KKImageThumbCell : UICollectionViewCell
@property(nonatomic,weak)id<KKImageThumbCellDelegate>delegate;
@property(nonatomic,readonly)UIView *contentBgView;
@property(nonatomic,readonly)UIImageView *imageView;
@property(nonatomic,assign)BOOL disable;
- (void)refreshCell:(KKPhotoInfo *)item cellType:(KKImageThumbCellType)type disable:(BOOL)disable;
#pragma mark -- 选中动画
- (void)selectAnimate;
@end
