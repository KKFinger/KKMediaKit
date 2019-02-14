//
//  KKPhotoPickerView.h
//  KKPhotoKit
//
//  Created by kkfinger on 2019/2/12.
//  Copyright © 2019 kkfinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKPhotoInfo.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KKPhotoGirdPickerViewDelegate<NSObject>
- (void)showImageActionSheetView;
@end

@interface KKPhotoGirdPickerView : UIView
@property(nonatomic,weak)id<KKPhotoGirdPickerViewDelegate>delegate;
@property(nonatomic,copy)void(^widgetHeightChanged)(CGFloat height);
- (CGFloat)fetchWidgetHeight;
- (NSInteger)maxSelPhotoCount;
- (NSInteger)curtSelPhotoCount;
- (void)addPhotoItem:(KKPhotoInfo *)item;
- (void)removePhotoItem:(KKPhotoInfo *)item;
- (NSArray<KKPhotoInfo *> *)fetchGallerySelectedArray;
@end

NS_ASSUME_NONNULL_END
