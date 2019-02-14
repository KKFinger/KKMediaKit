//
//  KKPhotoManager.m
//  KKPhotoKit
//
//  Created by finger on 2017/10/14.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKPhotoManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ReactiveCocoa.h>
#import "NSArray+Safe.h"
#import "NSDictionary+Safe.h"
#import <CoreServices/CoreServices.h>
#import <UIImage+GIF.h>
#import "UIImage+Extend.h"
#import "NSDate+KK.h"

static NSInteger maxThumbConcurrentCount = 50 ;//最多同时获取的缩略图个数

@interface KKPhotoManager ()<PHPhotoLibraryChangeObserver>
@property(nonatomic)PHCachingImageManager *cachingImageManager;//照片缓存，每次获取照片时先从缓存中查找
//注意，这两个变量只为了提高UICollectionView或者UItableView显示效率,不能用于其他模块的相片获取
@property(nonatomic)PHAssetCollection *albumCollection;//每一个相册对应一个PHAssetCollection
@property(nonatomic)PHFetchResult *albumAssets;//每一个相册的相片集合对应一个PHFetchResult

@property(nonatomic)NSMutableDictionary *imageInfos;

@property(nonatomic)PHImageRequestOptions *fetchThumbOptions;
@property(nonatomic)NSOperationQueue *fetchThumbQueue;

@property(atomic)NSCondition *tfLock;

@end

@implementation KKPhotoManager

+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc{
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary unregisterChangeObserver:self];
}

- (id)init{
    self = [super init];
    if (self){
        self.albumAssets = nil;
        self.albumCollection = nil;
        self.cachingImageManager = [[PHCachingImageManager alloc] init];
        self.imageInfos = [NSMutableDictionary new];
        
        self.fetchThumbQueue = [[NSOperationQueue alloc]init];
        self.fetchThumbQueue.maxConcurrentOperationCount = NSIntegerMax ;
        
        self.fetchThumbOptions = [[PHImageRequestOptions alloc]init];
        self.fetchThumbOptions.networkAccessAllowed = YES ;
        self.fetchThumbOptions.resizeMode = PHImageRequestOptionsResizeModeFast ;
        self.fetchThumbOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        
        self.tfLock = [[NSCondition alloc]init];
        
        PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
        [photoLibrary registerChangeObserver:self];
    }
    return self;
}

#pragma mark -- 清理

- (void)clear{
    [self.imageInfos enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        KKPhotoInfo *item = (KKPhotoInfo *)obj;
        item.displayImage = nil ;
        item.imageData = nil ;
        item.thumbImage = nil ;
        item.originalImage = nil ;
    }];
    [self.imageInfos removeAllObjects];
}

- (void)clearDisplayImage:(NSString *)idString{
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:idString];
    item.displayImage = nil ;
}

#pragma mark -- 照片库变动通知

- (void)photoLibraryDidChange:(PHChange *)changeInstance{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(photoLibraryDidChange) object:nil];
        [self performSelector:@selector(photoLibraryDidChange) withObject:nil afterDelay:0.3];
    });
}

- (void)photoLibraryDidChange{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KKNotifyPhotoLibraryDidChange object:nil];
    });
}

#pragma mark -- 用户权限

- (KKPhotoAuthorizationStatus)convertStatusWithPHAuthorizationStatus:(PHAuthorizationStatus)PHStatus{
    switch (PHStatus){
        case PHAuthorizationStatusNotDetermined:
            return KKPhotoAuthorizationStatusNotDetermined;
        case PHAuthorizationStatusDenied:
            return KKPhotoAuthorizationStatusDenied;
        case PHAuthorizationStatusRestricted:
            return KKPhotoAuthorizationStatusRestricted;
        case PHAuthorizationStatusAuthorized:
            return KKPhotoAuthorizationStatusAuthorized;
        default:
            return KKPhotoAuthorizationStatusRestricted;
    }
}

- (KKPhotoAuthorizationStatus)authorizationStatus{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    return [self convertStatusWithPHAuthorizationStatus:status];
}

- (void)requestAuthorization:(void (^)(KKPhotoAuthorizationStatus))handler{
    @weakify(self);
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        @strongify(self);
        if(handler){
            handler([self convertStatusWithPHAuthorizationStatus:status]);
        }
    }];
}

#pragma mark -- 获取相机胶卷相册(主相册)的id

- (NSString*)getCameraRollAlbumId{
    PHFetchResult *collectionsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (int i = 0; i < collectionsResult.count; i++){
        PHAssetCollection *collection = collectionsResult[i];
        NSInteger assetSubType = collection.assetCollectionSubtype ;
        if (assetSubType == PHAssetCollectionSubtypeSmartAlbumUserLibrary){
            return collection.localIdentifier;
        }
    }
    return nil ;
}

#pragma mark -- 相片是否选择

- (BOOL)querySelectStateWithIdentifier:(NSString *)identifier{
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:identifier];
    return item.isSelected;
}

#pragma mark -- 重置相册的PHAssetCollection及其对应的相片资源

- (void)resetCollectionWithAlbumId:(NSString *)albumId{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
    
    @weakify(self);
    [self getAlbumCollectionWithAlbumId:albumId block:^(PHAssetCollection *collection) {
        @strongify(self);
        self.albumCollection = collection;
        self.albumAssets = [PHAsset fetchAssetsInAssetCollection:self.albumCollection options:options];
    }];
}

#pragma mark -- 初始化相册相关参数,collection 可以是PHAssetCollection对象,也可以是相册id

- (void)initAlbumWithAlbumObj:(NSObject *)collection
                        block:(void(^)(BOOL done ,KKMediaAlbumInfo *albumInfo))hander
{
    if (collection == nil ){
        if(hander){
            hander(NO,nil);
        }
    }else{
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
        
        if([collection isKindOfClass:[PHAssetCollection class]]){
            self.albumCollection = (PHAssetCollection *)collection;
            self.albumAssets = [PHAsset fetchAssetsInAssetCollection:self.albumCollection options:options];
            KKMediaAlbumInfo *albumInfo = [self getAlbumInfoWithPHAssetCollection:self.albumCollection];
            if(hander){
                hander(YES,albumInfo);
            }
        }else if([collection isKindOfClass:[NSString class]]){
            @weakify(self);
            [self getAlbumCollectionWithAlbumId:(NSString *)collection block:^(PHAssetCollection *collection) {
                @strongify(self);
                self.albumCollection = collection;
                self.albumAssets = [PHAsset fetchAssetsInAssetCollection:self.albumCollection options:options];
                KKMediaAlbumInfo *albumInfo = [self getAlbumInfoWithPHAssetCollection:self.albumCollection];
                if(hander){
                    hander(YES,albumInfo);
                }
            }];
        }
    }
}

#pragma mark -- 创建相册

-(NSString *)createAlbumIfNeedWithName:(NSString *)name{
    //判断是否已存在
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection * assetCollection in assetCollections) {
        if ([assetCollection.localizedTitle isEqualToString:name]) {
            return assetCollection.localIdentifier;
        }
    }
    
    //创建新的相簿
    __block NSString *assetCollectionLocalIdentifier = nil;
    NSError *error = nil;
    //同步方法
    [[PHPhotoLibrary sharedPhotoLibrary]performChangesAndWait:^{
        // 创建相簿的请求
        assetCollectionLocalIdentifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    if (error)return nil;
    
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionLocalIdentifier] options:nil].lastObject.localIdentifier;
}

#pragma mark -- 图片缩略图获取，albumCollection和albumAssets在调用之前必须先初始化

//取消所有的缩略图的拉取工作
- (void)cancelAllThumbnailTask{
    [self.fetchThumbQueue cancelAllOperations];
    NSLog(@"取消所有的缩略图的拉取工作");
}

- (void)getThumbnailImageWithIndex:(NSInteger)index
                     needImageSize:(CGSize)size
                    isNeedDegraded:(BOOL)degraded
                             block:(void(^)(KKPhotoInfo *item))handler
{
    if(self.fetchThumbQueue.operationCount >= maxThumbConcurrentCount){
        [self.fetchThumbQueue cancelAllOperations];
        NSLog(@"获取缩略图并发个数过多，取消所有拉取请求");
    }
    
    @weakify(self);
    [self.fetchThumbQueue addOperationWithBlock:^{
        @strongify(self);
        if (self.albumCollection && self.albumAssets){
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [self getThumbnailImageWithAlbumAsset:self.albumAssets
                                            index:index
                                    needImageSize:size
                                   isNeedDegraded:degraded
                                            block:^(KKPhotoInfo *item)
             {
                 if(handler){
                     handler(item);
                 }
                 dispatch_semaphore_signal(semaphore);
             }];
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC));
        }else{
            if(handler){
                handler(nil);
            }
        }
    }];
}

- (void)getThumbnailImageWithAlbumAsset:(PHFetchResult *)assetsResult
                                  index:(NSInteger)index
                          needImageSize:(CGSize)size
                         isNeedDegraded:(BOOL)degraded
                                  block:(void(^)(KKPhotoInfo *item))handler
{
    if (index < assetsResult.count){
        PHAsset *asset = assetsResult[index];
        if(!asset){
            if(handler){
                handler(nil);
            }
            return ;
        }
        
        [self.tfLock lock];
        NSString *localIdentifier = asset.localIdentifier ;
        KKPhotoInfo *item = [self.imageInfos safeObjectForKey:localIdentifier];
        if(!item){
            item = [KKPhotoInfo new];
            item.identifier = localIdentifier;
            item.isGif = [[[[asset valueForKey:@"filename"]pathExtension]lowercaseString]isEqualToString:@"gif"];
            [self.imageInfos safeSetObject:item forKey:localIdentifier];
        }
        [self.tfLock unlock];
        
        item.imageIndex = index;
        
        [self.cachingImageManager requestImageForAsset:asset
                                            targetSize:size
                                           contentMode:PHImageContentModeAspectFill
                                               options:self.fetchThumbOptions
                                         resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
         {
             if (degraded == YES){
                 item.thumbImage = result;
                 if(handler){
                     handler(item);
                 }
             }else{
                 //PHImageResultIsDegradedKey  的值为1时，表示为小尺寸的缩略图，此时还在下载原尺寸的图
                 BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                 item.thumbImage = result;
                 if (isDegraded == NO){//图片完全加载
                     if(handler){
                         handler(item);
                     }
                 }
             }
         }];
    }else{
        if(handler){
            handler(nil);
        }
    }
}

#pragma mark -- 获取用于展示的图片

- (void)getDisplayImageWithIndex:(NSInteger)index
                   needImageSize:(CGSize)size
                  isNeedDegraded:(BOOL)degraded
                           block:(void (^)(KKPhotoInfo *item))handler{
    PHAsset *asset = self.albumAssets[index];
    if(!asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    CGFloat ratio = asset.pixelWidth / MAX(asset.pixelHeight,1.0) ;
    CGSize theSize = CGSizeMake(size.width,size.width/ratio);
    
    PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
    requireOptions.networkAccessAllowed = YES ;
    requireOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    requireOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    
    [self.tfLock lock];
    NSString *localIdentifier = asset.localIdentifier ;
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:localIdentifier];
    if(!item){
        item = [KKPhotoInfo new];
        item.identifier = localIdentifier;
        [self.imageInfos safeSetObject:item forKey:localIdentifier];
    }
    [self.tfLock unlock];
    
    item.imageIndex = index;
    
    [self.cachingImageManager requestImageDataForAsset:asset options:requireOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL finish = (![[info objectForKey:PHImageCancelledKey]boolValue] && ![info objectForKey:PHImageErrorKey]);
        if(degraded){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                item.imageSize = item.displayImage.size;
                if(item.isGif){
                    item.displayImage = [UIImage sd_animatedGIFWithData:imageData];
                    item.imageData = imageData;
                }else{
                    item.displayImage = [UIImage compressImage:[UIImage imageWithData:imageData] quality:1.0 size:theSize] ;
                    item.imageData = nil ;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(handler){
                        handler(item);
                    }
                });
            });
        }else{
            if(finish){
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                    item.imageSize = item.displayImage.size;
                    item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                    if(item.isGif){
                        item.displayImage = [UIImage sd_animatedGIFWithData:imageData];
                        item.imageData = imageData;
                    }else{
                        item.displayImage = [UIImage compressImage:[UIImage imageWithData:imageData] quality:1.0 size:theSize] ;
                        item.imageData = nil ;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(handler){
                            handler(item);
                        }
                    });
                });
            }
        }
    }];
}

- (void)getDisplayImageWithIdentifier:(NSString *)identifier
                        needImageSize:(CGSize)size
                       isNeedDegraded:(BOOL)degraded
                                block:(void (^)(KKPhotoInfo *item))handler{
    if(!identifier.length){
        if(handler){
            handler(nil);
        }
        return ;
    }
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
    if(!asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    CGFloat ratio = asset.pixelWidth / MAX(asset.pixelHeight,1.0) ;
    CGSize theSize = CGSizeMake(size.width,size.width/ratio);
    
    PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
    requireOptions.networkAccessAllowed = YES ;
    requireOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    requireOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    
    [self.tfLock lock];
    NSString *localIdentifier = asset.localIdentifier ;
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:localIdentifier];
    if(!item){
        item = [KKPhotoInfo new];
        item.identifier = localIdentifier;
        [self.imageInfos safeSetObject:item forKey:localIdentifier];
    }
    [self.tfLock unlock];
    
    [self.cachingImageManager requestImageDataForAsset:asset options:requireOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL finish = (![[info objectForKey:PHImageCancelledKey]boolValue] && ![info objectForKey:PHImageErrorKey]);
        if(degraded){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                item.imageSize = item.displayImage.size;
                item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                if(item.isGif){
                    item.displayImage = [UIImage sd_animatedGIFWithData:imageData];
                    item.imageData = imageData;
                }else{
                    item.displayImage = [UIImage compressImage:[UIImage imageWithData:imageData] quality:1.0 size:theSize] ;
                    item.imageData = nil ;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(handler){
                        handler(item);
                    }
                });
            });
        }else{
            if(finish){
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                    item.imageSize = item.displayImage.size;
                    item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                    if(item.isGif){
                        item.displayImage = [UIImage sd_animatedGIFWithData:imageData];
                        item.imageData = imageData;
                    }else{
                        item.displayImage = [UIImage compressImage:[UIImage imageWithData:imageData] quality:1.0 size:theSize] ;
                        item.imageData = nil ;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(handler){
                            handler(item);
                        }
                    });
                });
            }
        }
    }];
}

#pragma mark -- 获取原图

- (void)getOriginalImageWithIndex:(NSInteger)index
                            block:(void (^)(KKPhotoInfo *item))handler{
    PHAsset *asset = self.albumAssets[index];
    if(!asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
    requireOptions.networkAccessAllowed = YES ;
    
    [self.tfLock lock];
    NSString *localIdentifier = asset.localIdentifier ;
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:localIdentifier];
    if(!item){
        item = [KKPhotoInfo new];
        item.identifier = localIdentifier;
        [self.imageInfos safeSetObject:item forKey:localIdentifier];
    }
    [self.tfLock unlock];
    
    item.imageIndex = index;
    
    [self.cachingImageManager requestImageDataForAsset:asset options:requireOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL finish = (![[info objectForKey:PHImageCancelledKey]boolValue] && ![info objectForKey:PHImageErrorKey]);
        if(finish){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                if(item.isGif){
                    item.originalImage = [UIImage sd_animatedGIFWithData:imageData];
                    item.imageData = imageData;
                }else{
                    item.originalImage = [UIImage imageWithData:imageData];
                    item.imageData = nil ;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(handler){
                        handler(item);
                    }
                });
            });
        }
    }];
}

- (void)getOriginalImageDataWithIndex:(NSInteger)index
                                block:(void (^)(KKPhotoInfo *item))handler{
    PHAsset *asset = self.albumAssets[index];
    if(!asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
    requireOptions.networkAccessAllowed = YES ;
    
    [self.tfLock lock];
    NSString *localIdentifier = asset.localIdentifier ;
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:localIdentifier];
    if(!item){
        item = [KKPhotoInfo new];
        item.identifier = localIdentifier;
        [self.imageInfos safeSetObject:item forKey:localIdentifier];
    }
    [self.tfLock unlock];
    
    item.imageIndex = index;
    
    [self.cachingImageManager requestImageDataForAsset:asset options:requireOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL finish = (![[info objectForKey:PHImageCancelledKey]boolValue] && ![info objectForKey:PHImageErrorKey]);
        if(finish){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                item.imageData = imageData;
                item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(handler){
                        handler(item);
                    }
                });
            });
        }
    }];
}

- (void)getOriginalImageWithIdentifier:(NSString *)identifier
                                 block:(void (^)(KKPhotoInfo *item))handler{
    if(!identifier.length){
        if(handler){
            handler(nil);
        }
        return ;
    }
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
    if(!asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
    requireOptions.networkAccessAllowed = YES ;
    
    [self.tfLock lock];
    NSString *localIdentifier = asset.localIdentifier ;
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:localIdentifier];
    if(!item){
        item = [KKPhotoInfo new];
        item.identifier = localIdentifier;
        [self.imageInfos safeSetObject:item forKey:localIdentifier];
    }
    [self.tfLock unlock];
    
    [self.cachingImageManager requestImageDataForAsset:asset options:requireOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL finish = (![[info objectForKey:PHImageCancelledKey]boolValue] && ![info objectForKey:PHImageErrorKey]);
        if(finish){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                if(item.isGif){
                    item.originalImage = [UIImage sd_animatedGIFWithData:imageData];
                    item.imageData = imageData;
                }else{
                    item.originalImage = [UIImage imageWithData:imageData];
                    item.imageData = nil;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(handler){
                        handler(item);
                    }
                });
            });
        }
    }];
}

- (void)getOriginalImageDataWithIdentifier:(NSString *)identifier
                                     block:(void (^)(KKPhotoInfo *item))handler{
    if(!identifier.length){
        if(handler){
            handler(nil);
        }
        return ;
    }
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].firstObject;
    if(!asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
    requireOptions.networkAccessAllowed = YES ;
    
    [self.tfLock lock];
    NSString *localIdentifier = asset.localIdentifier ;
    KKPhotoInfo *item = [self.imageInfos safeObjectForKey:localIdentifier];
    if(!item){
        item = [KKPhotoInfo new];
        item.identifier = localIdentifier;
        [self.imageInfos safeSetObject:item forKey:localIdentifier];
    }
    [self.tfLock unlock];
    
    [self.cachingImageManager requestImageDataForAsset:asset options:requireOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL finish = (![[info objectForKey:PHImageCancelledKey]boolValue] && ![info objectForKey:PHImageErrorKey]);
        if(finish){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                item.imageData = imageData;
                item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
                item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(handler){
                        handler(item);
                    }
                });
            });
        }
    }];
}

#pragma mark - 获取PHAssetCollection 句柄

- (PHAssetCollection *)getAlbumCollectionWithAlbumId:(NSString *)albumId{
    //获取系统相册
    PHFetchResult *smartAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    if (smartAlbumsResult != nil){
        NSInteger albumCount = smartAlbumsResult.count;
        if ( albumCount > 0 ){
            for (int i = 0; i < albumCount; i++){
                PHAssetCollection *collection = smartAlbumsResult[i];
                if ([collection.localIdentifier isEqualToString:albumId]){
                    return collection;
                }
            }
        }
    }
    
    //自定义相册
    PHFetchResult *customAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    
    if (customAlbumsResult != nil){
        NSInteger albumCount = customAlbumsResult.count;
        if (albumCount >0 ){
            for (int i = 0; i < albumCount; i++){
                PHAssetCollection *collection = customAlbumsResult[i];
                if ([collection.localIdentifier isEqualToString:albumId]){
                    return collection;
                }
            }
        }
    }
    return nil;
}

- (void)getAlbumCollectionWithAlbumId:(NSString *)albumId block:(void(^)(PHAssetCollection *collection))callback{
    PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
    if(callback){
        callback(collection);
    }
}

#pragma mark -- 获取相册列表信息

- (void)getImageAlbumList:(void (^)(NSArray<KKMediaAlbumInfo*> *))handler{
    NSMutableArray<KKMediaAlbumInfo*> *array = [[NSMutableArray<KKMediaAlbumInfo*> alloc] initWithCapacity:0];
    //获取系统相册
    PHFetchResult *smartAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    if (smartAlbumsResult != nil){
        NSInteger albumCount = smartAlbumsResult.count;
        if (albumCount >0 ){
            for (int i = 0; i < albumCount; i++){
                PHAssetCollection *collection = smartAlbumsResult[i];
                NSString *albumTitle = collection.localizedTitle;
                NSInteger assetSubType = collection.assetCollectionSubtype ;
                if (albumTitle == nil){
                    continue;
                }
                if([[[UIDevice currentDevice]systemVersion]floatValue] >= 9.0){
                    if(assetSubType == PHAssetCollectionSubtypeSmartAlbumTimelapses ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumSlomoVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumBursts ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumAllHidden ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumPanoramas ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumFavorites ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumSelfPortraits ){
                        continue ;
                    }
                }else{
                    if(assetSubType == PHAssetCollectionSubtypeSmartAlbumTimelapses ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumSlomoVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumBursts ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumAllHidden ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumVideos ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumPanoramas ||
                       assetSubType == PHAssetCollectionSubtypeSmartAlbumFavorites){
                        continue ;
                    }
                }
                KKMediaAlbumInfo *info = [self getAlbumInfoWithPHAssetCollection:collection];
                if (info != nil && !info.isRecentDelete){
                    [array safeAddObject:info];
                }
            }
        }
    }
    
    //自定义相册
    PHFetchResult *customAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    if (customAlbumsResult != nil){
        NSInteger albumCount = customAlbumsResult.count;
        if (albumCount >0 ){
            for (int i = 0; i < albumCount ; i++){
                PHAssetCollection *collection = customAlbumsResult[i];
                NSString *albumTitle = collection.localizedTitle;
                if (albumTitle == nil){
                    continue;
                }
                KKMediaAlbumInfo *info = [self getAlbumInfoWithPHAssetCollection:collection];
                if (info != nil){
                    [array safeAddObject:info];
                }
            }
        }
    }
    if(handler){
        handler(array);
    }
}

#pragma mark -- 相册相关信息

- (KKMediaAlbumInfo *)getAlbumInfoWithPHAssetCollection:(PHAssetCollection *)collection{
    if (collection == nil){
        return nil;
    }
    
    NSInteger assetSubType = collection.assetCollectionSubtype ;
    
    PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    NSInteger assetsCount = 0;
    if (assetsResult !=nil){
        assetsCount = [assetsResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    }
    
    if(assetsCount == 0){
        return nil;
    }
    
    KKMediaAlbumInfo *info = [KKMediaAlbumInfo new];
    
    info.assetSubType = assetSubType ;
    info.albumName = collection.localizedTitle;
    info.albumId = collection.localIdentifier ;
    info.assetCount = assetsCount ;
    
    if (assetSubType == 1000000201 /*最近删除*/){
        info.canDeleteItem = NO ;
        info.isRecentDelete = YES ;
    }else{
        info.canDeleteItem = [collection canPerformEditOperation:PHCollectionEditOperationDeleteContent];
        info.isRecentDelete = NO ;
    }
    
    //rename album title
    info.canRename = [collection canPerformEditOperation:PHCollectionEditOperationRename];
    
    if (assetSubType == PHAssetCollectionSubtypeSmartAlbumUserLibrary){
        info.canAddItem = YES ;
    }else{
        info.canAddItem = [collection canPerformEditOperation:PHCollectionEditOperationAddContent];
    }
    
    //delete album
    info.canDelete = [collection canPerformEditOperation:PHCollectionEditOperationDelete];
    
    return info;
}

- (void)getAlbumInfoWithAlbumId:(NSString *)albumId block:(void(^)(KKMediaAlbumInfo *info))resultHandler{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @weakify(self);
        [self getAlbumCollectionWithAlbumId:albumId block:^(PHAssetCollection *collection) {
            @strongify(self);
            KKMediaAlbumInfo *info = [self getAlbumInfoWithPHAssetCollection:collection] ;
            if(resultHandler){
                resultHandler(info);
            }
        }];
    });
}

#pragma mark -- 根据相册的id，获取全部图片的id

- (void)getAlbumImageIdentifierWithAlbumId:(NSString *)albumId sort:(NSComparisonResult)comparison block:(void(^)(NSArray *array))handler{
    [self getAlbumCollectionWithAlbumId:albumId block:^(PHAssetCollection *collection) {
        if (collection != nil){
            NSMutableArray *array = [[NSMutableArray alloc]init];
            
            BOOL isAscending = YES;
            if (comparison == NSOrderedDescending){
                isAscending = NO;
            }
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:isAscending]];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            
            if (fetchResult.count == 0){
                if(handler){
                    handler(nil);
                }
                return ;
            }
            
            for (PHAsset *asset in fetchResult){
                if(!asset){
                    continue ;
                }
                
                NSString *identifier = asset.localIdentifier;
                [array safeAddObject:identifier];
            }
            if(handler){
                handler(array);
            }
        }else{
            if(handler){
                handler(nil);
            }
        }
    }];
}

#pragma mark -- 根据相册id和图片索引获取图片

- (void)getImageWithAlbumID:(NSString *)albumID
                      index:(NSInteger)index
              needImageSize:(CGSize)size
             isNeedDegraded:(BOOL)degraded
                       sort:(NSComparisonResult)comparison
                      block:(void (^)(KKPhotoInfo *item))handler
{
    @weakify(self);
    [self getAlbumCollectionWithAlbumId:albumID block:^(PHAssetCollection *collection) {
        @strongify(self);
        if (collection != nil){
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            BOOL isAscending = YES;
            if (comparison == NSOrderedDescending){
                isAscending = NO;
            }
            options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:isAscending]];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            
            if (fetchResult.count == 0){
                if(handler){
                    handler(nil);
                }
                return ;
            }
            
            PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
            requireOptions.networkAccessAllowed = YES ;
            requireOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
            requireOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            
            PHAsset *asset = fetchResult[index];
            if(!asset){
                if(handler){
                    handler(nil);
                }
                return ;
            }
            
            [self requestImageFromCacheWithAsset:asset
                                          targetSize:size
                                         contentMode:PHImageContentModeAspectFill
                                             options:requireOptions
                                      isNeedDegraded:degraded
                                               block:^(KKPhotoInfo *item)
             {
                 if(handler){
                     handler(item);
                 }
             }];
            
        }else{
            if(handler){
                handler(nil);
            }
        }
    }];
}

#pragma mark -- 根据相册id和图片id获取图片

- (void)getImageWithAlbumID:(NSString *)albumID
       imageLocalIdentifier:(NSString *)localIdentifier
              needImageSize:(CGSize)size
             isNeedDegraded:(BOOL)degraded
                       sort:(NSComparisonResult)comparison
                      block:(void (^)(KKPhotoInfo *item))handler
{
    PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumID];
    
    if (collection != nil){
        if(!localIdentifier.length){
            if(handler){
                handler(nil);
            }
            return ;
        }
        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil].firstObject;
        if(!asset){
            if(handler){
                handler(nil);
            }
            return ;
        }
        
        CGSize theSize = size;
        if (CGSizeEqualToSize(size, CGSizeZero) == YES){
            theSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
        }
        
        PHImageRequestOptions *requireOptions = [[PHImageRequestOptions alloc]init];
        requireOptions.networkAccessAllowed = YES ;
        requireOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        requireOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        
        [self requestImageFromCacheWithAsset:asset
                                  targetSize:theSize
                                 contentMode:PHImageContentModeAspectFill
                                     options:requireOptions
                              isNeedDegraded:degraded
                                       block:^(KKPhotoInfo *item)
         {
             if(handler){
                 handler(item);
             }
         }];
        
    }else{
        if(handler){
            handler(nil);
        }
    }
}

#pragma mark- 删除或移除照片

- (void)deleteImageWithAlbumId:(NSString*)albumId
             imageLocalIdArray:(NSArray *)localIdArray
                         block:(void(^)(BOOL suc))handler
{
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    
    PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
    
    NSMutableArray *willDeleteList = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (NSString *localId in localIdArray){
        if(!localId.length){
            continue;
        }
        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil].firstObject;
        if (asset){
            [willDeleteList addObject:asset];
        }
    }
    
    if([collection canPerformEditOperation:PHCollectionEditOperationDeleteContent]){
        //delete
        [photoLibrary performChanges:^{
            [PHAssetChangeRequest deleteAssets:willDeleteList];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if(handler){
                handler(success);
            }
        }];
    }else if ([collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]){
        //remove
        [photoLibrary performChanges:^{
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            [changeRequest removeAssets:willDeleteList];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if(handler){
                handler(success);
            }
        }];
    }
}

- (void)deleteImageWithAlbumId:(NSString*)albumId
                    indexArray:(NSArray*)indexArray
                          sort:(NSComparisonResult)comparison
                         block:(void(^)(bool suc))handler
{
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    
    [self getAlbumCollectionWithAlbumId:albumId block:^(PHAssetCollection *collection) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:(comparison == NSOrderedAscending)?YES:NO]];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
        PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        
        NSMutableArray *willDeleteList = [[NSMutableArray alloc] initWithCapacity:0];
        
        for (NSNumber *indexNumber in indexArray){
            NSInteger index = [indexNumber integerValue];
            PHAsset *asset = assetsResult[index];
            [willDeleteList addObject:asset];
        }
        
        if([collection canPerformEditOperation:PHCollectionEditOperationDeleteContent]){
            //delete
            [photoLibrary performChanges:^{
                [PHAssetChangeRequest deleteAssets:willDeleteList];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if(handler){
                    handler(success);
                }
            }];
        }else if ([collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]){
            //remove
            [photoLibrary performChanges:^{
                PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                [changeRequest removeAssets:willDeleteList];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if(handler){
                    handler(success);
                }
            }];
        }
    }];
}

#pragma mark -- 图片添加

- (void)addImageToAlbumWithImage:(UIImage *)image
                         albumId:(NSString *)albumId
                         options:(PHImageRequestOptions *)options
                           block:(void(^)(KKPhotoInfo *))block
{
    @autoreleasepool {
        @weakify(self);
        __block NSString *assetId = nil ;
        //异步添加相片
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            @strongify(self);
            PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
            PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            
            PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            changeAssetRequest.creationDate = [NSDate date];
            
            PHObjectPlaceholder *assetPlaceholder = [changeAssetRequest placeholderForCreatedAsset];
            
            assetId = assetPlaceholder.localIdentifier ;
            
            if ([collection canPerformEditOperation:PHCollectionEditOperationAddContent]){
                [collectionChangeRequest addAssets:@[assetPlaceholder]];
            }
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                NSLog(@"存储错误");
                if(block){
                    block(nil);
                }
                return;
            }
            
            if(!assetId.length){
                if(block){
                    block(nil);
                }
                return ;
            }
            
            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
            if(!asset){
                block(nil);
                return ;
            }
            
            [self requestImageDataWithAlbumId:albumId
                                            asset:asset
                                          options:options
                                            block:^(KKPhotoInfo *item)
             {
                 if(block){
                     block(item);
                 }
             }];
            
        }];
        
    }
}

- (void)addImageFilesToAlbumWithImages:(NSArray *)imageFiles
                               albumId:(NSString *)albumId
                               options:(PHImageRequestOptions *)options
                                 block:(void(^)(NSArray *))block
{
    @autoreleasepool {
        @weakify(self);
        __block NSMutableArray *assetPlaceholderArray = [[NSMutableArray alloc]init];
        __block NSMutableArray *imageInfos = [[NSMutableArray alloc]init];
        
        //异步添加相片
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            @strongify(self);
            PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
            PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            for (NSString *imageFilePath in imageFiles){
                UIImage *image = [UIImage imageWithContentsOfFile:imageFilePath];
                if (image){
                    PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                    changeAssetRequest.creationDate = [NSDate date];
                    if (changeAssetRequest != nil){
                        [assetPlaceholderArray addObject:[changeAssetRequest placeholderForCreatedAsset]];
                    }
                    
                }
            }
            
            if ([collection canPerformEditOperation:PHCollectionEditOperationAddContent]){
                [collectionChangeRequest addAssets:@[assetPlaceholderArray]];
            }
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                if(block){
                    block(nil);
                }
                return;
            }
            
            for(PHObjectPlaceholder *placeholder in assetPlaceholderArray){
                
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                NSString *assetId = placeholder.localIdentifier ;
                
                if(!assetId.length){
                    continue;
                }
                
                PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                if(!asset){
                    continue ;
                }
                
                [self requestImageDataWithAlbumId:albumId
                                                asset:asset
                                              options:options
                                                block:^(KKPhotoInfo *item)
                 {
                     if(item){
                         [imageInfos addObject:item];
                     }
                     dispatch_semaphore_signal(semaphore);
                 }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
            if(block){
                block(imageInfos);
            }
        }];
    }
}

//可用于保存gif图
- (void)addImageData:(NSData *)data
           toAlbumId:(NSString *)albumId
               block:(void(^)(BOOL suc))block
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f) {
        @weakify(self);
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            @strongify(self);
            PHAssetCollection *collection = [self getAlbumCollectionWithAlbumId:albumId];
            
            PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            
            PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
            options.shouldMoveFile = YES;
            
            PHAssetCreationRequest *changeAssetRequest = [PHAssetCreationRequest creationRequestForAsset];
            changeAssetRequest.creationDate = [NSDate date];
            [changeAssetRequest addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
            
            PHObjectPlaceholder *assetPlaceholder = [changeAssetRequest placeholderForCreatedAsset];
            
            if ([collection canPerformEditOperation:PHCollectionEditOperationAddContent]){
                [collectionChangeRequest addAssets:@[assetPlaceholder]];
            }
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(block){
                        block(NO);
                    }
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(block){
                        block(YES);
                    }
                });
            }
        }];
    }else {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        @weakify(library);
        [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            @strongify(library);
            NSString* groupId = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
            if([groupId isEqualToString:albumId]){
                NSDictionary *metadata = @{@"UTI":(__bridge NSString *)kUTTypeGIF};
                // 开始写数据
                [library writeImageDataToSavedPhotosAlbum:data metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(block){
                                block(NO);
                            }
                        });
                    }else{
                        [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                            if ([group isEditable]) {
                                [group addAsset:asset];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if(block){
                                        block(YES);
                                    }
                                });
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if(block){
                                        block(NO);
                                    }
                                });
                            }
                            
                        } failureBlock:^(NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if(block){
                                    block(NO);
                                }
                            });
                        }];
                    }
                }];
            }
        } failureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(block){
                    block(NO);
                }
            });
        }];
    }
#else
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    @weakify(library);
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        @strongify(library);
        NSString* groupId = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
        if([groupId isEqualToString:albumId]){
            NSDictionary *metadata = @{@"UTI":(__bridge NSString *)kUTTypeGIF};
            // 开始写数据
            [library writeImageDataToSavedPhotosAlbum:data metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(block){
                            block(NO);
                        }
                    });
                }else{
                    [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        if ([group isEditable]) {
                            [group addAsset:asset];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if(block){
                                    block(YES);
                                }
                            });
                        }else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if(block){
                                    block(NO);
                                }
                            });
                        }
                        
                    } failureBlock:^(NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(block){
                                block(NO);
                            }
                        });
                    }];
                }
            }];
        }
    } failureBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block){
                block(NO);
            }
        });
    }];
#endif
}



#pragma mark -- ////////////////////private//////////////////////



#pragma mark -- 从图片缓存中获取图片

- (void)requestImageFromCacheWithAsset:(PHAsset *)asset
                            targetSize:(CGSize)size
                           contentMode:(PHImageContentMode)contentMode
                               options:(PHImageRequestOptions *)options
                        isNeedDegraded:(BOOL)degraded
                                 block:(void(^)(KKPhotoInfo *item))handler
{
    if(!asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    KKPhotoInfo *item = [KKPhotoInfo new];
    
    [self.cachingImageManager requestImageForAsset:asset
                                        targetSize:size
                                       contentMode:contentMode
                                           options:options
                                     resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
     {
         if (degraded == YES){
             item.identifier = asset.localIdentifier;
             item.imageName = [[info objectForKey:@"PHImageFileURLKey"]lastPathComponent];
             item.thumbImage = result;
             
             if(handler){
                 handler(item);
             }
         }else{
             //PHImageResultIsDegradedKey  的值为1时，表示为小尺寸的缩略图，此时还在下载原尺寸的图
             BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
             
             if (isDegraded == NO){
                 item.identifier = asset.localIdentifier;
                 item.thumbImage = result;
                 
                 if(handler){
                     handler(item);
                 }
             }
         }
     }];
}

#pragma mark -- 从图片缓存中获取数据(NSData)

- (void)requestImageDataWithAlbumId:(NSString *)albumId
                              asset:(PHAsset *)asset
                            options:(PHImageRequestOptions *)options
                              block:(void(^)(KKPhotoInfo *item))handler
{
    KKPhotoInfo *item = [KKPhotoInfo new];
    
    if(!albumId.length || !asset){
        if(handler){
            handler(nil);
        }
        return ;
    }
    
    @autoreleasepool {
        [self.cachingImageManager requestImageDataForAsset:asset
                                                   options:options
                                             resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
         {
             if (info || imageData) {
                 
                 NSDate *createDate = asset.creationDate;
                 item.imageName = [[info objectForKey:@"PHImageFileURLKey"] lastPathComponent];
                 if (item.imageName == nil){
                     item.imageName = [createDate stringWithFormat:@"MMddyyyy"];
                 }
                 
                 item.albumId = albumId;
                 item.createDate = [createDate stringWithFormat:@"yyyy/MM/dd hh:mm:ss"];
                 item.modifyDate = [asset.modificationDate stringWithFormat:@"yyyy/MM/dd hh:mm:ss"];
                 item.imageSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
                 item.dataSize = imageData.length;
                 item.identifier = asset.localIdentifier ;
                 item.imageData = imageData;
                 item.isGif = [dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF];
                 
                 if(handler){
                     handler(item);
                 }
                 
             }else{
                 if(handler){
                     handler(nil);
                 }
             }
         }];
    }
}

@end
