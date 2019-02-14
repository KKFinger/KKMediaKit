//
//  KKPhotoPickerBarView.h
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/16.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KKPhotoPickerBarViewDelegate<NSObject>
- (void)previewSelectedImages;
- (void)doneSelectedImages;
@end

@interface KKPhotoPickerBarView : UIView
@property(nonatomic,weak)id<KKPhotoPickerBarViewDelegate>delegate;
@property(nonatomic,assign)NSInteger selectCount;
@end
