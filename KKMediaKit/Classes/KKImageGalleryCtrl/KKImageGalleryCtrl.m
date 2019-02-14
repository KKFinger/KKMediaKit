//
//  KKImageGalleryCtrl.m
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/5.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "KKImageGalleryCtrl.h"
#import "KKImageThumbCell.h"
#import "KKPhotoManager.h"
#import "KKBlockAlertView.h"
#import "KKAppTools.h"
#import "KKGalleryImagePreview.h"
#import "KKPhotoPickerBarView.h"

static NSString *cellReuseIdentifier = @"cellReuseIdentifier";
static CGFloat space = 1.0 ;
static CGFloat bottomBarViewHeight = 50 ;

@interface KKImageGalleryCtrl ()<KKImageThumbCellDelegate,UICollectionViewDelegate,UICollectionViewDataSource,KKPhotoPickerBarViewDelegate>
@property(nonatomic)UICollectionView *collectView;
@property(nonatomic)KKBlockAlertView *alertView;
@property(nonatomic)KKPhotoPickerBarView *barView;
@property(nonatomic)KKMediaAlbumInfo *albumInfo;
@property(nonatomic,copy)NSString *albumId;
@property(nonatomic,assign)CGSize cellSize;
@property(nonatomic,assign)BOOL couldContinueSel ;
@property(nonatomic)NSMutableArray *tempSelectArray;
@end

@implementation KKImageGalleryCtrl

- (instancetype)initWithAlbumId:(NSString *)albumId{
    self = [super init];
    if(self){
        self.albumId = albumId;
        self.couldContinueSel = YES ;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadAlbumInfoWithAlbumId:self.albumId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGFloat cellWH = (self.view.width - 3 * space ) / 4.0;
    self.cellSize = CGSizeMake(cellWH, cellWH);
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)dealloc{
    [self.tempSelectArray removeAllObjects];
    self.tempSelectArray = nil ;
    NSLog(@"%@ dealloc --- ",NSStringFromClass([self class]));
}

#pragma mark -- 设置UI

- (void)setupUI{
    //导航栏遮挡视图的问题
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"相机胶卷";
    self.navigationItem.leftBarButtonItem = [KKAppTools createItemWithTitle:@"返回" imageName:nil target:self selector:@selector(quitSelf) isLeft:YES];
    self.navigationItem.rightBarButtonItem = [KKAppTools createItemWithTitle:@"取消" imageName:nil target:self selector:@selector(quitPicker) isLeft:NO];
    self.navigationController.navigationBar.borderType = KKBorderTypeBottom;
    self.navigationController.navigationBar.borderColor = [[UIColor grayColor]colorWithAlphaComponent:0.1];
    self.navigationController.navigationBar.borderThickness = 0.3;
    self.navigationController.navigationBar.translucent = NO ;
    
    [self.view addSubview:self.collectView];
    [self.view addSubview:self.barView];
    [self.collectView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [self.barView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.height.mas_equalTo(bottomBarViewHeight + KKSafeAreaBottomHeight);
    }];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(fetchCurrentSelCount)]){
        self.barView.selectCount = [self.delegate fetchCurrentSelCount];
    }
}

#pragma mark -- 加载相册信息

- (void)loadAlbumInfoWithAlbumId:(NSString *)albumId{
    [self.view showSysActivityWithStyle:UIActivityIndicatorViewStyleGray];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        KKPhotoAuthorizationStatus status = [[KKPhotoManager sharedInstance]authorizationStatus];
        while (status == KKPhotoAuthorizationStatusNotDetermined) {
            usleep(1.0 * 1000.0);
            status = [[KKPhotoManager sharedInstance]authorizationStatus] ;
        }
        if(status == KKPhotoAuthorizationStatusAuthorized){
            if(self.albumId == nil){
                self.albumId = [[KKPhotoManager sharedInstance]getCameraRollAlbumId];
            }
            [[KKPhotoManager sharedInstance]initAlbumWithAlbumObj:self.albumId block:^(BOOL done, KKMediaAlbumInfo *albumInfo) {
                self.albumInfo = albumInfo;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectView reloadData];
                    [self.navigationItem setTitle:self.albumInfo.albumName];
                    [self.view hiddenActivity];
                });
            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view hiddenActivity];
                KKBlockAlertView *view = [KKBlockAlertView new];
                [view showWithTitle:@"相册权限" message:@"腾讯医典没有相册权限" cancelButtonTitle:@"知道了" otherButtonTitles:@"去设置" block:^(NSInteger re_code, NSDictionary *userInfo) {
                    if(re_code == 1){
                        [KKAppTools jumpToAppSetting];
                    }
                }];
                self.alertView = view ;
            });
        }
    });
}

#pragma mark -- UICollectionViewDelegate,UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.albumInfo.assetCount;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    KKImageThumbCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell setDelegate:self];
    [cell.contentBgView setAlpha:1.0];
    
    NSInteger scale = [[UIScreen mainScreen] scale];
    CGSize size = CGSizeMake(CGRectGetWidth(cell.bounds)*scale, CGRectGetHeight(cell.bounds)*scale);
    [[KKPhotoManager sharedInstance]getThumbnailImageWithIndex:indexPath.row needImageSize:size isNeedDegraded:NO block:^(KKPhotoInfo *item) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL disable = (!self.couldContinueSel && (!item.isSelected));
            [cell refreshCell:item cellType:KKImageThumbCellTypeSelect disable:disable];
        });
    }];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return self.cellSize;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
}

//设置水平间距 (同一行的cell的左右间距）
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return space;
}

//垂直间距 (同一列cell上下间距)
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return space;
}

#pragma mark -- 完全停止滚动

//完全停止滚动
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self reloadVisiableCell];
}

#pragma Mark -- 刷新可见区域的cell

- (void)reloadVisiableCell{
    [UIView performWithoutAnimation:^{
        NSArray *indexArray = [self.collectView indexPathsForVisibleItems];
        for(NSIndexPath *indexPath in indexArray){
            KKImageThumbCell *cell = (KKImageThumbCell *)[self.collectView cellForItemAtIndexPath:indexPath];
            [cell setDelegate:self];
            [cell.contentBgView setAlpha:1.0];

            NSInteger scale = [[UIScreen mainScreen] scale];
            CGSize size = CGSizeMake(CGRectGetWidth(cell.bounds)*scale, CGRectGetHeight(cell.bounds)*scale);

            [[KKPhotoManager sharedInstance]getThumbnailImageWithIndex:indexPath.row needImageSize:size isNeedDegraded:NO block:^(KKPhotoInfo *item) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL disable = (!self.couldContinueSel && (!item.isSelected));
                    [cell refreshCell:item cellType:KKImageThumbCellTypeSelect disable:disable];
                });
            }];
        }
    }];
}

#pragma mark -- KKImageThumbCellDelegate

- (void)selectImage:(KKImageThumbCell *)cell photoItem:(KKPhotoInfo *)item{
    if(self.delegate && [self.delegate respondsToSelector:@selector(selectImageItem:isSel:complete:)]){
        @weakify(self);
        [self.delegate selectImageItem:item isSel:!item.isSelected complete:^(BOOL canOperator,BOOL couldContinueSel,NSInteger curtSelCnt,NSInteger maxLimitCnt) {
            @strongify(self);
            if(canOperator){
                item.isSelected = !item.isSelected;
                [cell refreshCell:item cellType:KKImageThumbCellTypeSelect disable:!self.couldContinueSel];
                [cell selectAnimate];
                if(item.isSelected){
                    BOOL hasAdd = NO ;
                    for(NSString *idString in self.tempSelectArray){
                        if([idString isEqualToString:item.identifier]){
                            hasAdd = YES ;
                            break;
                        }
                    }
                    if(!hasAdd){
                        [self.tempSelectArray safeAddObject:item.identifier];
                    }
                }else{
                    for(NSInteger i = 0 ; i < self.tempSelectArray.count ; i++){
                        NSString *strId = [self.tempSelectArray safeObjectAtIndex:i];
                        if([strId isEqualToString:item.identifier]){
                            [self.tempSelectArray safeRemoveObjectAtIndex:i];
                            break;
                        }
                    }
                }
            }
            if(self.couldContinueSel != couldContinueSel){
                self.couldContinueSel = couldContinueSel;
                [self reloadVisiableCell];
            }
            self.barView.selectCount = curtSelCnt;
        }];
    }
}

- (void)showPreviewView:(KKImageThumbCell *)cell{
    NSIndexPath *indexPath = [self.collectView indexPathForCell:cell];
    [[KKPhotoManager sharedInstance]getAlbumImageIdentifierWithAlbumId:self.albumId
                                                                  sort:NSOrderedDescending
                                                                 block:^(NSArray *array)
     {
         [self showPreviewWithSelIndex:indexPath.row imageArray:array];
     }];
}

#pragma mark -- KKPhotoPickerBarViewDelegate

- (void)doneSelectedImages{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)previewSelectedImages{
    if(self.delegate && [self.delegate respondsToSelector:@selector(fetchGallerySelectedArray)]){
        NSArray *array = [self.delegate fetchGallerySelectedArray];
        NSMutableArray *selArray = [NSMutableArray new];
        for(KKPhotoInfo *info in array){
            [selArray safeAddObject:info.identifier];
        }
        [self previewSelectedImages:selArray];
    }
}

#pragma mark -- 点击cell预览

- (void)showPreviewWithSelIndex:(NSInteger)index imageArray:(NSArray *)array{
    KKImageThumbCell *cell = (KKImageThumbCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGRect frame = [cell.contentBgView convertRect:cell.contentBgView.frame toView:self.collectView];
    
    KKGalleryImagePreview *browser = [[KKGalleryImagePreview alloc]initWithImageArray:array selIndex:index albumId:self.albumId selCount:0];
    browser.frame = CGRectMake(0, 0, UIDeviceScreenWidth, UIDeviceScreenHeight);
    browser.defaultHideAnimateWhenDragFreedom = NO ;
    browser.zoomAnimateWhenShow = NO;
    browser.zoomAnimateWhenHide = YES ;
    browser.oriView = self.collectView;
    browser.oriFrame = frame;
    if(self.delegate && [self.delegate respondsToSelector:@selector(fetchCurrentSelCount)]){
        browser.selCount = [self.delegate fetchCurrentSelCount];
    }
    
    @weakify(browser);
    [browser setHideImageAnimateBlock:^(UIImage *image,CGRect fromFrame,CGRect toFrame) {
        @strongify(browser);
        UIImageView *imageView = [YYAnimatedImageView new];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.frame = fromFrame ;
        imageView.layer.masksToBounds = YES ;
        [self.collectView addSubview:imageView];
        [UIView animateWithDuration:0.3 animations:^{
            imageView.frame = toFrame;
        }completion:^(BOOL finished) {
            [imageView removeFromSuperview];
            [browser removeFromSuperview];
            for(KKImageThumbCell *cell in self.collectView.visibleCells){
                cell.contentBgView.alpha = 1.0 ;
            }
        }];
    }];
    
    [browser setAlphaViewIfNeedBlock:^(BOOL shouldAlphaView,NSInteger curtSelIndex){
        for(KKImageThumbCell *cell in self.collectView.visibleCells){
            cell.contentBgView.alpha = 1.0 ;
        }
        KKImageThumbCell *cell = (KKImageThumbCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:curtSelIndex inSection:0]];
        cell.contentBgView.alpha = !shouldAlphaView ;
    }];
    
    [browser setImageIndexChangeBlock:^(NSInteger imageIndex,void(^updeteOriFrame)(CGRect oriFrame)){
        [self.collectView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:imageIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        KKImageThumbCell *cell = (KKImageThumbCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:imageIndex inSection:0]];
        CGRect frame = [cell.contentBgView convertRect:cell.contentBgView.frame toView:self.collectView];
        if(updeteOriFrame){
            updeteOriFrame(frame);
        }
    }];

    [browser setSelectImageBlock:^(KKPhotoInfo *item,BOOL isSelect,NSInteger selIndex,void(^selectCallback)(BOOL canSelect,NSInteger selCount,NSInteger maxSelCount)){
        if(self.delegate && [self.delegate respondsToSelector:@selector(selectImageItem:isSel:complete:)]){
            @weakify(self);
            [self.delegate selectImageItem:item isSel:!item.isSelected complete:^(BOOL canOperator,BOOL couldContinueSel,NSInteger curtSelCnt,NSInteger maxLimitCnt) {
                @strongify(self);
                if(canOperator){
                    item.isSelected = !item.isSelected;
                    KKImageThumbCell *cell = (KKImageThumbCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selIndex inSection:0]];
                    [cell refreshCell:item cellType:KKImageThumbCellTypeSelect disable:!self.couldContinueSel];
                    [cell selectAnimate];
                }
                if(selectCallback){
                    selectCallback(canOperator,curtSelCnt,maxLimitCnt);
                }
                self.barView.selectCount = curtSelCnt;
                
                self.couldContinueSel = couldContinueSel;
                
                [self reloadVisiableCell];
            }];
        }
    }];

    [[UIApplication sharedApplication].keyWindow addSubview:browser];
    if(browser.zoomAnimateWhenShow){
        [browser viewWillAppear];
    }else{
        [browser startShow];
    }
}

#pragma mark -- 预览已经选择的图片

- (void)previewSelectedImages:(NSArray<NSString *> *)array{
    KKGalleryImagePreview *browser = [[KKGalleryImagePreview alloc]initWithImageArray:array selIndex:0 albumId:self.albumId selCount:0];
    browser.frame = CGRectMake(0, 0, UIDeviceScreenWidth, UIDeviceScreenHeight);
    browser.defaultHideAnimateWhenDragFreedom = YES;
    browser.zoomAnimateWhenShow = NO;
    browser.zoomAnimateWhenHide = NO ;
    if(self.delegate && [self.delegate respondsToSelector:@selector(fetchCurrentSelCount)]){
        browser.selCount = [self.delegate fetchCurrentSelCount];
    }
    
    [browser setSelectImageBlock:^(KKPhotoInfo *item,BOOL isSelect,NSInteger selIndex,void(^selectCallback)(BOOL canSelect,NSInteger selCount,NSInteger maxSelCount)){
        if(self.delegate && [self.delegate respondsToSelector:@selector(selectImageItem:isSel:complete:)]){
            @weakify(self);
            [self.delegate selectImageItem:item isSel:!item.isSelected complete:^(BOOL canOperator,BOOL couldContinueSel,NSInteger curtSelCnt,NSInteger maxLimitCnt) {
                @strongify(self);
                if(canOperator){
                    item.isSelected = !item.isSelected;
                    KKImageThumbCell *cell = (KKImageThumbCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selIndex inSection:0]];
                    [cell refreshCell:item cellType:KKImageThumbCellTypeSelect disable:!self.couldContinueSel];
                    [cell selectAnimate];
                }
                if(selectCallback){
                    selectCallback(canOperator,curtSelCnt,maxLimitCnt);
                }
                
                self.couldContinueSel = couldContinueSel;
                
                self.barView.selectCount = curtSelCnt;
                
                [self reloadVisiableCell];
            }];
        }
    }];
    
    [[UIApplication sharedApplication].keyWindow addSubview:browser];
    if(browser.zoomAnimateWhenShow){
        [browser viewWillAppear];
    }else{
        [browser startShow];
    }
}

#pragma mark -- 退出

- (void)quitSelf{
    NSArray *viewcontrollers = self.navigationController.viewControllers;
    if(viewcontrollers.count>1) {
        if ([viewcontrollers objectAtIndex:viewcontrollers.count-1] == self) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else{
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)quitPicker{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -- @property

- (UICollectionView *)collectView{
    if(!_collectView){
        _collectView = ({
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
            layout.footerReferenceSize = CGSizeMake(UIDeviceScreenWidth, bottomBarViewHeight + KKSafeAreaBottomHeight);
            UICollectionView *view = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
            view.delegate= self;
            view.dataSource= self;
            view.backgroundColor = [UIColor whiteColor];
            [view registerClass:[KKImageThumbCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
            view;
        });
    }
    return _collectView;
}

- (KKPhotoPickerBarView *)barView{
    if(!_barView){
        _barView = ({
            KKPhotoPickerBarView *view = [KKPhotoPickerBarView new];
            view.backgroundColor = [UIColor whiteColor];
            view.borderType = KKBorderTypeTop;
            view.borderColor = [[UIColor grayColor]colorWithAlphaComponent:0.1];
            view.borderThickness = 0.3 ;
            view.delegate = self ;
            view ;
        });
    }
    return _barView;
}

- (NSMutableArray *)tempSelectArray{
    if(!_tempSelectArray){
        _tempSelectArray = [NSMutableArray new];
    }
    return _tempSelectArray;
}

@end
