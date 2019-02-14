//
//  KKQuestionImagePreview.m
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/17.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "KKPhotoGirdPreview.h"
#import "KKPhotoManager.h"
#import "KKGalleryPreviewCell.h"
#import "KKImageZoomView.h"
#import "KKBlockAlertView.h"

static NSString *cellReuseIdentifier = @"cellReuseIdentifier";

#define ImageHorizPading 20 //每张图片之间的间距
#define ImageItemWith (UIDeviceScreenWidth + ImageHorizPading)

@interface KKQuestionImagePreview ()<UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,KKImageZoomViewDelegate>
@property(nonatomic)UICollectionView *collectView;
@property(nonatomic)UIButton *closeBtn;
@property(nonatomic)UILabel *indexLabel;
@property(nonatomic)UIButton *deleteBtn;
@property(nonatomic)KKBlockAlertView *blockView;
@property(nonatomic,strong)CAGradientLayer *topGradient;

@property(nonatomic,copy)NSArray<KKPhotoInfo *> *imageArray;
@property(nonatomic,assign)NSInteger selIndex;
@property(nonatomic,assign)BOOL showView;

@property(nonatomic,assign)UIStatusBarStyle barStyle;

@property(nonatomic,assign)BOOL shouldIgnoreKVO;

@end

@implementation KKQuestionImagePreview

- (instancetype)initWithImageArray:(NSArray<KKPhotoInfo *> *)imageArray selIndex:(NSInteger)selIndex selCount:(NSInteger)selCount{
    self = [super init];
    if(self){
        self.selIndex = selIndex;
        self.imageArray = imageArray;
        self.showView = YES ;
        self.selCount = selCount;
        self.barStyle = [[UIApplication sharedApplication]statusBarStyle];
        self.dragContentView.backgroundColor = [UIColor blackColor];
        self.enableHorizonDrag = NO ;
        self.enableVerticalDrag = NO ;
    }
    return self ;
}

- (void)dealloc{
    [self.collectView removeObserver:self forKeyPath:@"contentSize"];
    NSLog(@"%@ dealloc",NSStringFromClass([self class]));
}

#pragma mark -- 视图的显示和消失

- (void)viewWillAppear{
    [super viewWillAppear];
    [self setupUI];
}

- (void)viewWillDisappear{
    [super viewWillDisappear];
    [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:NO];
    [[UIApplication sharedApplication]setStatusBarStyle:self.barStyle];
}

- (void)viewDidAppear{
    [super viewDidAppear];
    self.shouldIgnoreKVO = YES ;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.topGradient.frame = CGRectMake(0, 0, self.width, KKStatusBarHeight + 50);
}

#pragma mark -- 设置UI

- (void)setupUI{
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self.dragContentView addSubview:self.collectView];
    [self.dragContentView addSubview:self.closeBtn];
    [self.dragContentView addSubview:self.indexLabel];
    [self.dragContentView addSubview:self.deleteBtn];
    [self.dragContentView.layer insertSublayer:self.topGradient below:self.closeBtn.layer];
    
    [self.collectView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.height.mas_equalTo(self.dragContentView);
        make.width.mas_equalTo(ImageItemWith);
    }];
    
    [self.closeBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.dragContentView).mas_offset(KKStatusBarHeight + 5);
        make.left.mas_equalTo(self.dragContentView).mas_offset(KKPaddingLarge);
        make.size.mas_equalTo(CGSizeMake(44, 30));
    }];
    
    [self.indexLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.dragContentView);
        make.centerY.mas_equalTo(self.closeBtn);
    }];
    
    [self.deleteBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.closeBtn);
        make.right.mas_equalTo(self.dragContentView).mas_offset(-KKPaddingLarge);
        make.size.mas_equalTo(CGSizeMake(44, 30));
    }];
}

#pragma mark -- 点击删除按钮

- (void)deleteBtnClicked{
    @weakify(self);
    self.blockView = [KKBlockAlertView new];
    [self.blockView showWithTitle:nil message:@"是否删除图片" cancelButtonTitle:@"取消" otherButtonTitles:@"确定" block:^(NSInteger re_code, NSDictionary *userInfo) {
        @strongify(self);
        if(re_code == 1){
            KKPhotoInfo *info = [self.imageArray safeObjectAtIndex:self.selIndex];
            if(self.deleteImageBlock){
                @weakify(self);
                self.deleteImageBlock(info, self.selIndex, ^(NSInteger selCount, NSInteger maxSelCount,NSArray<KKPhotoInfo *> *array) {
                    @strongify(self);
                    self.selCount = array.count;
                    self.imageArray = array;
                    [self.collectView reloadData];
                    
                    NSInteger selectIndex = self.selIndex;
                    if(selectIndex >= array.count){
                        selectIndex = array.count - 1 ;
                    }
                    self.selIndex = selectIndex;
                    
                    self.indexLabel.text = [NSString stringWithFormat:@"%ld/%ld",selectIndex+1,self.selCount];
                    
                    if(array.count <= 0){
                        [self hideViewAnimate];
                    }
                });
            }
        }
    }];
}

#pragma mark -- UICollectionViewDelegate,UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.imageArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    KKPhotoInfo *info = [self.imageArray safeObjectAtIndex:indexPath.row];
    KKGalleryPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    cell.conetntImageView.zoomViewDelegate = self;
    if(info.photoType == KKPhotoInfoTypeGallery){
        NSString *idString = info.identifier;
        [[KKPhotoManager sharedInstance]getDisplayImageWithIdentifier:idString
                                                        needImageSize:CGSizeMake(2 * UIDeviceScreenWidth, 2 * UIDeviceScreenHeight)
                                                       isNeedDegraded:YES
                                                                block:^(KKPhotoInfo *item)
         {
             cell.image = item.displayImage;
         }];
    }else if(info.photoType == KKPhotoInfoTypeCamera){
        cell.image = info.displayImage;
    }else if(info.photoType == KKPhotoInfoTypeNetwork){
        [cell showImageWithUrl:info.url placeHolder:info.thumbImage];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(ImageItemWith, UIDeviceScreenHeight);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
}

//设置水平间距 (同一行的cell的左右间距）
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

//垂直间距 (同一列cell上下间距)
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

#pragma mark -- KKImageZoomViewDelegate

- (void)tapImageZoomView{
    self.showView = !self.showView;
    self.closeBtn.hidden = !self.showView;
    self.indexLabel.hidden = !self.showView;
    self.deleteBtn.hidden = !self.showView;
    self.topGradient.hidden = !self.showView;
    [[UIApplication sharedApplication]setStatusBarHidden:!self.showView withAnimation:NO];
}

- (void)imageViewDidZoom:(KKImageZoomView *)zoomView{
    self.dragContentView.backgroundColor = [UIColor blackColor];
    self.enableFreedomDrag = NO ;
}

#pragma mark -- UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    self.enableFreedomDrag = NO ;
    
    CGPoint offset = self.collectView.contentOffset;
    CGFloat progress = offset.x / (CGFloat)ImageItemWith;
    NSInteger index = offset.x / (CGFloat)ImageItemWith;
    
    //设置上下、当前三张图片的透明度
    NSInteger nextIndex = index + 1 ;
    if(nextIndex < self.imageArray.count){
        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:nextIndex inSection:0]];
        [cell setAlpha:fabs(progress-index)];
    }
    
    KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [cell setAlpha:1 - fabs((progress-index))];
    
    NSInteger perIndex = index - 1 ;
    if(perIndex >= 0){
        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:perIndex inSection:0]];
        [cell setAlpha:fabs((index - progress))];
    }
}

//结束拉拽视图
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    CGPoint offset = self.collectView.contentOffset;
    NSInteger index = offset.x / ImageItemWith;
    if(index < 0 || index >= self.imageArray.count){
        return ;
    }
    self.indexLabel.text = [NSString stringWithFormat:@"%ld/%ld",index+1,self.selCount];
}

//完全停止滚动
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = self.collectView.contentOffset;
    NSInteger index = offset.x / (CGFloat)ImageItemWith;
    if(index < 0 || index >= self.imageArray.count){
        return ;
    }
    
    self.selIndex = index ;
    
    KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selIndex inSection:0]];
    [cell setAlpha:1.0];
    
    NSInteger nextIndex = self.selIndex + 1 ;
    NSString *idString = [self.imageArray safeObjectAtIndex:nextIndex].identifier;
    if(nextIndex < self.imageArray.count){
        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:nextIndex inSection:0]];
        [cell setAlpha:1.0];
        [cell.conetntImageView setImage:nil];
    }
    //[[KKPhotoManager sharedInstance]clearDisplayImage:idString];
    
    NSInteger perIndex = self.selIndex - 1 ;
    idString = [self.imageArray safeObjectAtIndex:perIndex].identifier;
    if(perIndex >= 0){
        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:perIndex inSection:0]];
        [cell setAlpha:1.0];
        [cell.conetntImageView setImage:nil];
    }
    //[[KKPhotoManager sharedInstance]clearDisplayImage:idString];
    
    self.enableFreedomDrag = NO ;
    
    self.indexLabel.text = [NSString stringWithFormat:@"%ld/%ld",index+1,self.selCount];
}

#pragma mark -- 开始、拖拽中、结束拖拽

- (void)dragBeginWithPoint:(CGPoint)pt{
    self.enableFreedomDrag = NO ;
    KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selIndex inSection:0]];
    KKImageZoomView *view = cell.conetntImageView;
    UIImageView *imageView = view.imageView;
    if(view.zoomScale != view.minimumZoomScale){
        return ;
    }
    
    //只有选中图片且不在缩放的情况下才允许自由拖拽
    CGPoint targetPt = [self.dragContentView convertPoint:pt toView:view];
    if(CGRectContainsPoint(imageView.frame, targetPt) && (view.contentSize.height <= cell.height)){
        self.enableFreedomDrag = YES ;
        view.bounces = NO ;
        view.scrollEnabled = NO ;
    }
}

- (void)dragingWithPoint:(CGPoint)pt{
    self.collectView.scrollEnabled = NO ;
    self.collectView.bounces = NO ;
    if(self.enableFreedomDrag){
        self.closeBtn.hidden = YES;
        self.deleteBtn.hidden = YES;
        self.indexLabel.hidden = YES;
        self.topGradient.hidden = YES;
        self.dragContentView.backgroundColor = [UIColor clearColor];
        
        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selIndex inSection:0]];
        KKImageZoomView *view = cell.conetntImageView;
        UIImageView *imageView = view.imageView;
        
        view.zoomScale = 1.0;
        view.scrollEnabled = NO ;
        view.bounces = NO ;
        
        imageView.layer.transform = CATransform3DMakeScale(self.dragViewBg.alpha,self.dragViewBg.alpha,0);
    }
    
    [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:NO];
}

- (void)dragEndWithPoint:(CGPoint)pt shouldHideView:(BOOL)hideView{
    KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selIndex inSection:0]];
    KKImageZoomView *view = cell.conetntImageView;
    UIImageView *imageView = view.imageView;
    
    view.bounces = YES ;
    view.scrollEnabled = YES ;
    
    self.collectView.bounces = YES ;
    self.collectView.scrollEnabled = YES ;
    
    if(view.zoomScale != view.minimumZoomScale){
        return ;
    }
    
    if(self.enableFreedomDrag){
        if(!hideView){
            self.dragContentView.backgroundColor = [UIColor blackColor];
            self.closeBtn.hidden = !self.showView;
            self.indexLabel.hidden = !self.showView;
            self.deleteBtn.hidden = !self.showView;
            self.topGradient.hidden = !self.showView;
            
            [UIView animateWithDuration:0.3 animations:^{
                imageView.layer.transform = CATransform3DIdentity;
                self.dragContentView.alpha = 1.0 ;
            }completion:^(BOOL finished) {
            }];
            
            [[UIApplication sharedApplication]setStatusBarHidden:!self.showView withAnimation:NO];
            
        }else{
            [self hideViewAnimate];
        }
    }else{
        self.dragContentView.backgroundColor = [UIColor blackColor];
    }
    
    self.enableFreedomDrag = NO ;
}

#pragma mark -- KVO

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if(self.shouldIgnoreKVO){
        return ;
    }
    if(object == self.collectView && [keyPath isEqualToString:@"contentSize"]) {
        [self.collectView setContentOffset:CGPointMake(self.selIndex * ImageItemWith, 0)];
    }
}

#pragma mark -- 消失动画

- (void)hideViewAnimate{
    [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:NO];
    [[UIApplication sharedApplication]setStatusBarStyle:self.barStyle];
    [self startHide];
}

#pragma mark -- @property setter

- (void)setSelCount:(NSInteger)selCount{
    _selCount = selCount;
    self.indexLabel.text = [NSString stringWithFormat:@"%ld/%ld",self.selIndex+1,selCount];
}

#pragma mark -- @property getter

- (UICollectionView *)collectView{
    if(!_collectView){
        _collectView = ({
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
            layout.scrollDirection =  UICollectionViewScrollDirectionHorizontal;
            UICollectionView *view = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
            view.delegate= self;
            view.dataSource= self;
            view.showsHorizontalScrollIndicator = NO ;
            view.showsVerticalScrollIndicator = NO ;
            view.pagingEnabled = YES ;
            view.backgroundColor = [UIColor clearColor];
            [view registerClass:[KKGalleryPreviewCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
            [view addObserver:self forKeyPath:@"contentSize"options:NSKeyValueObservingOptionNew context:NULL];//用于第一次进来时跳转到相应的图片
            view;
        });
    }
    return _collectView;
}

- (UIButton *)closeBtn{
    if(!_closeBtn){
        _closeBtn = ({
            UIButton *view = [UIButton new];
            //[view setTitle:@"关闭" forState:UIControlStateNormal];
            //[view.titleLabel setFont:[UIFont systemFontOfSize:17]];
            //[view setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [view setImage:[UIImage imageNamed:@"close_w_big"] forState:UIControlStateNormal];
            [view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [view addTarget:self action:@selector(hideViewAnimate) forControlEvents:UIControlEventTouchUpInside];
            view ;
        });
    }
    return _closeBtn;
}

- (UILabel *)indexLabel{
    if(!_indexLabel){
        _indexLabel = ({
            UILabel *view = [UILabel new];
            view.textAlignment = NSTextAlignmentCenter;
            view.textColor = [UIColor whiteColor];
            view.font = [UIFont systemFontOfSize:17];
            view.lineBreakMode = NSLineBreakByCharWrapping;
            view ;
        });
    }
    return _indexLabel;
}

- (UIButton *)deleteBtn{
    if(!_deleteBtn){
        _deleteBtn = ({
            UIButton *view = [UIButton new];
            //[view setTitle:@"删除" forState:UIControlStateNormal];
            //[view.titleLabel setFont:[UIFont systemFontOfSize:17]];
            //[view setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [view setImage:[UIImage imageNamed:@"delete_w"] forState:UIControlStateNormal];
            [view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            [view addTarget:self action:@selector(deleteBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            [view setSelected:NO];
            view ;
        });
    }
    return _deleteBtn;
}

- (CAGradientLayer *)topGradient{
    if(!_topGradient){
        _topGradient = [CAGradientLayer layer];
        _topGradient.colors = @[(__bridge id)[[UIColor blackColor]colorWithAlphaComponent:0.8].CGColor,(__bridge id)[UIColor clearColor].CGColor];
        _topGradient.startPoint = CGPointMake(0, 0);
        _topGradient.endPoint = CGPointMake(0.0, 1.0);
    }
    return _topGradient;
}

@end
