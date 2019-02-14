//
//  KKPhotoManager.h
//  KKPhotoKit
//
//  Created by finger on 2017/10/14.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "KKMediaAlbumInfo.h"
#import "KKPhotoInfo.h"
#import "KKPhotoKitDef.h"

@interface KKPhotoManager : NSObject

+ (instancetype)sharedInstance;

#pragma mark -- 清理

- (void)clear;
- (void)clearDisplayImage:(NSString *)idString;

#pragma mark -- 用户权限

- (KKPhotoAuthorizationStatus )convertStatusWithPHAuthorizationStatus:(PHAuthorizationStatus)PHStatus;

- (KKPhotoAuthorizationStatus)authorizationStatus;

- (void)requestAuthorization:(void (^)(KKPhotoAuthorizationStatus))handler;

#pragma mark -- 获取相机胶卷相册(主相册)的id

- (NSString*)getCameraRollAlbumId;

#pragma mark -- 相片是否选择

- (BOOL)querySelectStateWithIdentifier:(NSString *)identifier;

#pragma mark -- 重置相册的PHAssetCollection及其对应的相片资源

- (void)resetCollectionWithAlbumId:(NSString *)albumId;

#pragma mark -- 初始化相册相关参数,collection 可以是PHAssetCollection对象,也可以是相册id

- (void)initAlbumWithAlbumObj:(NSObject *)collection
                        block:(void(^)(BOOL done ,KKMediaAlbumInfo *albumInfo))hander;

#pragma mark -- 创建相册

-(NSString *)createAlbumIfNeedWithName:(NSString *)name;

#pragma mark -- 图片缩略图获取(专用)

//取消所有的图片拉取工作
- (void)cancelAllThumbnailTask;

- (void)getThumbnailImageWithIndex:(NSInteger)index
                     needImageSize:(CGSize)size
                    isNeedDegraded:(BOOL)degraded
                             block:(void(^)(KKPhotoInfo *item))handler;

- (void)getThumbnailImageWithAlbumAsset:(PHFetchResult *)assetsResult
                                  index:(NSInteger)index
                          needImageSize:(CGSize)size
                         isNeedDegraded:(BOOL)degraded
                                  block:(void(^)(KKPhotoInfo *item))handler;

#pragma mark -- 获取用于展示的图片

- (void)getDisplayImageWithIndex:(NSInteger)index
                   needImageSize:(CGSize)size
                  isNeedDegraded:(BOOL)degraded
                           block:(void (^)(KKPhotoInfo *item))handler;

- (void)getDisplayImageWithIdentifier:(NSString *)identifier
                        needImageSize:(CGSize)size
                       isNeedDegraded:(BOOL)degraded
                                block:(void (^)(KKPhotoInfo *item))handler;

#pragma mark -- 获取原图

- (void)getOriginalImageWithIndex:(NSInteger)index
                            block:(void (^)(KKPhotoInfo *item))handler;

- (void)getOriginalImageDataWithIndex:(NSInteger)index
                                block:(void (^)(KKPhotoInfo *item))handler;

- (void)getOriginalImageWithIdentifier:(NSString *)identifier
                                 block:(void (^)(KKPhotoInfo *item))handler;

- (void)getOriginalImageDataWithIdentifier:(NSString *)identifier
                                     block:(void (^)(KKPhotoInfo *item))handler;

#pragma mark - 获取PHAssetCollection 句柄

- (PHAssetCollection *)getAlbumCollectionWithAlbumId:(NSString *)albumId;

- (void)getAlbumCollectionWithAlbumId:(NSString *)albumId block:(void(^)(PHAssetCollection *collection))callback;

#pragma mark -- 获取相册列表信息

- (void)getImageAlbumList:(void (^)(NSArray<KKMediaAlbumInfo*> *))handler;

#pragma mark -- 相册相关信息

- (KKMediaAlbumInfo *)getAlbumInfoWithPHAssetCollection:(PHAssetCollection *)collection;

#pragma mark -- 根据相册的id，获取全部图片的id

- (void)getAlbumImageIdentifierWithAlbumId:(NSString *)albumId sort:(NSComparisonResult)comparison block:(void(^)(NSArray *array))handler;

#pragma mark -- 根据相册id和图片索引获取图片

- (void)getImageWithAlbumID:(NSString *)albumID
                      index:(NSInteger)index
              needImageSize:(CGSize)size
             isNeedDegraded:(BOOL)degraded
                       sort:(NSComparisonResult)comparison
                      block:(void (^)(KKPhotoInfo *item))handler;

#pragma mark- 删除或移除照片

- (void)deleteImageWithAlbumId:(NSString*)albumId
             imageLocalIdArray:(NSArray *)localIdArray
                         block:(void(^)(BOOL suc))handler;

- (void)deleteImageWithAlbumId:(NSString*)albumId
                    indexArray:(NSArray*)indexArray
                          sort:(NSComparisonResult)comparison
                         block:(void(^)(bool suc))handler;

#pragma mark- 图片添加

- (void)addImageToAlbumWithImage:(UIImage *)image
                         albumId:(NSString *)albumId
                         options:(PHImageRequestOptions *)options
                           block:(void(^)(KKPhotoInfo *))block;

- (void)addImageFilesToAlbumWithImages:(NSArray *)imageFiles
                               albumId:(NSString *)albumId
                               options:(PHImageRequestOptions *)options
                                 block:(void(^)(NSArray *))block;

//可用于保存gif图
- (void)addImageData:(NSData *)data
           toAlbumId:(NSString *)albumId
               block:(void(^)(BOOL suc))block;

@end
