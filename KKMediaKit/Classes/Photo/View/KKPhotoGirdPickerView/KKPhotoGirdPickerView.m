//
//  KKPhotoPickerView.m
//  KKPhotoKit
//
//  Created by kkfinger on 2019/2/12.
//  Copyright © 2019 kkfinger. All rights reserved.
//

#import "KKPhotoGirdPickerView.h"
#import "KKPhotoInfo.h"
#import "KKImageThumbCell.h"
#import "KKPhotoGirdPreview.h"

static CGFloat lrPadding = 15 ;
static NSInteger maxImageCount = 9 ;
static CGFloat space = 3.0 ;
static NSString *cellReuseIdentifier = @"cellReuseIdentifier";

@interface KKPhotoGirdPickerView()<UICollectionViewDelegate,UICollectionViewDataSource,UITextViewDelegate,KKImageThumbCellDelegate>
@property(nonatomic)UICollectionView *collectView;
@property(nonatomic)CGFloat cellWH;
@property(nonatomic)NSMutableArray<KKPhotoInfo *> *dataArray;
@end

@implementation KKPhotoGirdPickerView

- (instancetype)init{
    self = [super init];
    if(self){
        [self setupUI];
    }
    return self ;
}

- (void)dealloc{
    [self.dataArray removeAllObjects];
    self.dataArray = nil ;
    
    [self.collectView removeObserver:self forKeyPath:@"contentSize"];
    
    NSLog(@"%@ dealloc --- ",NSStringFromClass([self class]));
}

#pragma mark -- 设置UI

- (void)setupUI{
    [self addSubview:self.collectView];
    
    self.cellWH = ([[UIScreen mainScreen]bounds].size.width - 2 * space - 2 * lrPadding) / 3.0;
    
    KKPhotoInfo *item = [KKPhotoInfo new];
    item.thumbImage = [UIImage imageNamed:@"addIcon"];
    item.photoType = KKPhotoInfoTypePlaceholderImage ;
    item.identifier = [[NSUUID UUID]UUIDString];
    [self.dataArray safeAddObject:item];
    
    [self.collectView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self);
        make.left.mas_equalTo(self).mas_offset(lrPadding);
        make.right.mas_equalTo(self).mas_offset(-lrPadding);
        make.height.mas_equalTo(0);
    }];
}

#pragma mark -- UICollectionViewDelegate,UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return MIN(self.dataArray.count, maxImageCount);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    KKPhotoInfo *item = [self.dataArray safeObjectAtIndex:indexPath.row];
    KKImageThumbCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell refreshCell:item cellType:KKImageThumbCellTypeDelete disable:NO];
    [cell setDelegate:self];
    
    cell.layer.borderColor = [[UIColor grayColor]colorWithAlphaComponent:0.1].CGColor;
    cell.layer.borderWidth = 0.3 ;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.cellWH, self.cellWH);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    KKPhotoInfo *item = [self.dataArray safeObjectAtIndex:indexPath.row];
    if(item.photoType == KKPhotoInfoTypePlaceholderImage){
        if(self.delegate && [self.delegate respondsToSelector:@selector(showImageActionSheetView)]){
            [self.delegate showImageActionSheetView];
        }
    }else{
        [self showPreviewWithSelIndex:indexPath.row imageArray:[self fetchAllImages]];
    }
}

//设置水平间距 (同一行的cell的左右间距）
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return space;
}

//垂直间距 (同一列cell上下间距)
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return space;
}

#pragma mark -- 获取高度

- (CGFloat)fetchWidgetHeight{
    return self.collectView.contentSize.height;
}

#pragma mark -- KKImageThumbCellDelegate

- (void)deleteImage:(KKImageThumbCell *)cell photoItem:(KKPhotoInfo *)item{
    for(NSInteger i = 0 ; i < self.dataArray.count ; i++){
        KKPhotoInfo *target = [self.dataArray safeObjectAtIndex:i];
        if([target.identifier isEqualToString:item.identifier]){
            item.isSelected = NO ;
            [self.dataArray safeRemoveObjectAtIndex:i];
            [self.collectView reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if(self.widgetHeightChanged){
                    self.widgetHeightChanged([self fetchWidgetHeight]);
                }
            });
            break;
        }
    }
}

- (void)showPreviewView:(KKImageThumbCell *)cell{
    NSIndexPath *indexPath = [self.collectView indexPathForCell:cell];
    KKPhotoInfo *target = [self.dataArray safeObjectAtIndex:indexPath.row];
    if(target.photoType == KKPhotoInfoTypePlaceholderImage){
        if(self.delegate && [self.delegate respondsToSelector:@selector(showImageActionSheetView)]){
            [self.delegate showImageActionSheetView];
        }
    }else{
        [self showPreviewWithSelIndex:indexPath.row imageArray:[self fetchAllImages]];
    }
}

#pragma mark -- 显示预览视图

- (void)showPreviewWithSelIndex:(NSInteger)index imageArray:(NSArray *)array{
    for(NSInteger i = 0 ; i < array.count ; i++){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        KKImageThumbCell *cell = (KKImageThumbCell *)[self.collectView cellForItemAtIndexPath:indexPath];
        KKPhotoInfo *item = [array safeObjectAtIndex:i];
        item.thumbImage = cell.imageView.image;
    }
    KKQuestionImagePreview *browser = [[KKQuestionImagePreview alloc]initWithImageArray:array selIndex:index selCount:array.count];
    browser.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    @weakify(self);
    [browser setDeleteImageBlock:^(KKPhotoInfo *photoItem, NSInteger deleteIndex, void (^deleteCallback)(NSInteger selCount, NSInteger maxSelCount,NSArray<KKPhotoInfo *> *array)) {
        @strongify(self);
        [self removePhotoItem:photoItem];
        if(deleteCallback){
            deleteCallback([self curtSelPhotoCount],[self maxSelPhotoCount],[self fetchAllImages]);
        }
    }];
    
    [[UIApplication sharedApplication].keyWindow addSubview:browser];
    [browser startShow];
}

#pragma mark -- 最大的图片个数

- (NSInteger)maxSelPhotoCount{
    return maxImageCount;
}

#pragma mark -- 当前选择的图片个数

- (NSInteger)curtSelPhotoCount{
    return self.dataArray.count-1;
}

#pragma mark -- 添加图片

- (void)addPhotoItem:(KKPhotoInfo *)item{
    [item setIsNewAdd:YES];
    NSInteger curtSelCount = [self curtSelPhotoCount];
    [self.dataArray insertObject:item atIndex:curtSelCount];
    [self.collectView reloadData];
}

#pragma mark -- 删除图片

- (void)removePhotoItem:(KKPhotoInfo *)item{
    for(NSInteger i = 0 ; i < self.dataArray.count ; i++){
        KKPhotoInfo *target = [self.dataArray safeObjectAtIndex:i];
        if([target.identifier isEqualToString:item.identifier]){
            [item setIsNewAdd:NO];
            [target setIsNewAdd:NO];
            [self.dataArray safeRemoveObjectAtIndex:i];
            [self.collectView reloadData];
            break;
        }
    }
}

#pragma mark -- 获取从相册选择的图片

- (NSArray<KKPhotoInfo *> *)fetchGallerySelectedArray{
    NSMutableArray *array = [NSMutableArray new];
    for(NSInteger i = 0 ; i < self.dataArray.count; i++){
        KKPhotoInfo *item = [self.dataArray safeObjectAtIndex:i];
        if(item.photoType == KKPhotoInfoTypePlaceholderImage ||
           item.photoType == KKPhotoInfoTypeCamera ||
           item.photoType == KKPhotoInfoTypeNetwork){
            continue ;
        }
        [array safeAddObject:item];
    }
    return array;
}

#pragma mark -- 获取全部的图片

- (NSArray<KKPhotoInfo *> *)fetchAllImages{
    NSMutableArray *array = [NSMutableArray new];
    for(NSInteger i = 0 ; i < self.dataArray.count; i++){
        KKPhotoInfo *item = [self.dataArray safeObjectAtIndex:i];
        if(item.photoType == KKPhotoInfoTypePlaceholderImage){
            continue ;
        }
        [array safeAddObject:item];
    }
    return array;
}

#pragma mark -- KVO

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if(object == self.collectView && [keyPath isEqualToString:@"contentSize"]) {
        CGFloat height = self.collectView.contentSize.height ;
        [self.collectView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(height);
        }];
        if(self.widgetHeightChanged){
            self.widgetHeightChanged(height);
        }
    }
}

#pragma mark -- @property getter

- (UICollectionView *)collectView{
    if(!_collectView){
        _collectView = ({
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
            UICollectionView *view = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
            view.delegate= self;
            view.dataSource= self;
            view.backgroundColor = [UIColor whiteColor];
            [view registerClass:[KKImageThumbCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
            [view addObserver:self forKeyPath:@"contentSize"options:NSKeyValueObservingOptionNew context:NULL];
            view;
        });
    }
    return _collectView;
}

- (NSMutableArray<KKPhotoInfo *> *)dataArray{
    if(!_dataArray){
        _dataArray = [NSMutableArray new];
    }
    return _dataArray;
}

@end
