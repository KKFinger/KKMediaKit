//
//  KKPhotoInfo.h
//  KKPhotoKit
//
//  Created by finger on 2017/10/14.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger,KKPhotoInfoType) {
    KKPhotoInfoTypeGallery,//相片来自相册
    KKPhotoInfoTypePlaceholderImage,//默认的占位图
    KKPhotoInfoTypeCamera,//相片来自摄像头
    KKPhotoInfoTypeNetwork,//相片来自网络
};

typedef NS_ENUM(NSInteger, KKImageUploadState){
    KKImageUploadStateNone,
    KKImageUploadStateUploading,
    KKImageUploadStateFinish,
    KKImageUploadStateFail,
} ;

@interface KKPhotoInfo : NSObject
@property(nonatomic,copy)NSString *identifier;
@property(nonatomic,copy)NSString *imageName;
@property(nonatomic,assign)NSInteger imageIndex;
@property(nonatomic,copy)NSString *albumId;//相片所在的相册
@property(nonatomic,copy)NSString *createDate;
@property(nonatomic,copy)NSString *modifyDate;
@property(nonatomic,assign)CGSize imageSize;
@property(nonatomic,assign)CGFloat dataSize;
@property(nonatomic,strong)UIImage *thumbImage;//缩略图
@property(nonatomic,strong)UIImage *displayImage;//专门用来展示的
@property(nonatomic)UIImage *originalImage;//原图
@property(nonatomic)NSData *imageData;
@property(nonatomic)NSString *url;//网络图片的url
@property(nonatomic)NSString *thumbUrl;//网络图片缩略图的url
@property(nonatomic,assign)BOOL isSelected;//相片是否被选择
@property(nonatomic,assign)BOOL isNewAdd;//是否是新添加
@property(nonatomic,assign)BOOL isGif;//是否是新添加
@property(nonatomic,assign)KKPhotoInfoType photoType;//相片的类型
@property(nonatomic,assign)KKImageUploadState uploadState;
@end
