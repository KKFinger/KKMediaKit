//
//  KKGalleryImagePreview.m
//  KKPhotoKit
//
//  Created by finger on 2017/10/24.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKGalleryImagePreview.h"
#import "KKPhotoManager.h"
#import "KKGalleryPreviewCell.h"
#import "KKImageZoomView.h"

static CGFloat selCountLabelWH = 20 ;
static NSString *cellReuseIdentifier = @"cellReuseIdentifier";

#define ImageHorizPading 20 //每张图片之间的间距
#define ImageItemWith (UIDeviceScreenWidth + ImageHorizPading)

@interface KKGalleryImagePreview ()<UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,KKImageZoomViewDelegate>
@property(nonatomic)UICollectionView *collectView;
@property(nonatomic)UIButton *closeBtn;
@property(nonatomic)UILabel *selCountLabel;
@property(nonatomic)UIButton *doneBtn;
@property(nonatomic)UIButton *selBtn;

@property(nonatomic,strong)CAGradientLayer *topGradient;
@property(nonatomic,strong)CAGradientLayer *bottomGradient;

@property(nonatomic,copy)NSArray<NSString *> *imageArray;
@property(nonatomic,copy)NSString *albumId;
@property(nonatomic,assign)NSInteger selIndex;
@property(nonatomic,assign)BOOL showView;
@property(nonatomic,assign)BOOL shouldIgnoreKVO;

@property(nonatomic,assign)UIStatusBarStyle barStyle;

@end

@implementation KKGalleryImagePreview

- (instancetype)initWithImageArray:(NSArray<NSString *> *)imageArray selIndex:(NSInteger)selIndex albumId:(NSString *)albumId selCount:(NSInteger)selCount{
    self = [super init];
    if(self){
        self.selIndex = selIndex;
        self.imageArray = imageArray;
        self.albumId = albumId;
        self.dragViewBg.alpha = 0;
        self.showView = YES ;
        self.selCount = selCount;
        self.zoomAnimateWhenShow = YES ;
        self.zoomAnimateWhenHide = YES ;
        self.enableHorizonDrag = NO ;
        self.enableVerticalDrag = NO ;
        self.barStyle = [[UIApplication sharedApplication]statusBarStyle];
        self.selBtn.selected = [[KKPhotoManager sharedInstance]querySelectStateWithIdentifier:[self.imageArray safeObjectAtIndex:self.selIndex]];
        if(!self.albumId.length){
            self.albumId = [[KKPhotoManager sharedInstance]getCameraRollAlbumId];
        }
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
    if(self.zoomAnimateWhenShow){
        [self showEnterAnimate];
    }else{
        self.dragViewBg.alpha = 1;
        self.topGradient.hidden = NO;
        self.bottomGradient.hidden = NO;
        self.doneBtn.hidden = NO ;
        self.selBtn.hidden = NO ;
        self.selCountLabel.hidden = !self.selCount ;
        self.closeBtn.hidden = NO ;
        self.collectView.hidden = NO;
        [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    }
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
    self.topGradient.frame = CGRectMake(0, 0, self.width, 80);
    self.bottomGradient.frame = CGRectMake(0, self.height - 80, self.width, 80);
}

#pragma mark -- 设置UI

- (void)setupUI{
    [self.dragContentView addSubview:self.collectView];
    [self.dragContentView addSubview:self.closeBtn];
    [self.dragContentView addSubview:self.selCountLabel];
    [self.dragContentView addSubview:self.doneBtn];
    [self.dragContentView addSubview:self.selBtn];
    [self.dragContentView.layer insertSublayer:self.topGradient below:self.closeBtn.layer];
    [self.dragContentView.layer insertSublayer:self.bottomGradient below:self.selBtn.layer];
    
    [self.collectView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.height.mas_equalTo(self.dragContentView);
        make.width.mas_equalTo(ImageItemWith);
    }];
    
    [self.closeBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.dragContentView).mas_offset(KKStatusBarHeight + 5);
        make.left.mas_equalTo(self.dragContentView).mas_offset(KKPaddingLarge);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    [self.selCountLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.closeBtn);
        make.right.mas_equalTo(self.doneBtn.mas_left);
        make.size.mas_equalTo(CGSizeMake(selCountLabelWH, selCountLabelWH));
    }];
    
    [self.doneBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.dragContentView).mas_offset(-KKPaddingLarge);
        make.centerY.mas_equalTo(self.closeBtn);
        make.size.mas_equalTo(CGSizeMake(44, 30));
    }];
    
    [self.selBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.mas_equalTo(self.dragContentView).mas_offset(-KKPaddingLarge);
        make.bottom.mas_equalTo(self.dragContentView).mas_offset(iPhoneXSeries ? -KKSafeAreaBottomHeight: -KKPaddingNormal);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];
}

#pragma mark -- 显示动画

- (void)showEnterAnimate{
    [KKKeyWindow showSysActivityWithStyle:UIActivityIndicatorViewStyleGray];
    
    NSString *idString = [self.imageArray safeObjectAtIndex:self.selIndex];
    [[KKPhotoManager sharedInstance]getDisplayImageWithIdentifier:idString
                                                    needImageSize:UIDeviceScreenSize
                                                   isNeedDegraded:NO
                                                            block:^(KKPhotoInfo *item)
     {
         [KKKeyWindow hiddenActivity];
         
         UIImage *image = item.displayImage;
         CGFloat imageW = UIDeviceScreenWidth;
         CGFloat imageH = imageW / (image.size.width / image.size.height);
         CGRect frame = CGRectMake(0, (self.dragContentView.height - imageH) / 2.0, imageW, imageH);
         
         CGRect fromRect = [self.oriView convertRect:self.oriFrame toView:self.dragContentView];
         UIImageView *imageView = [YYAnimatedImageView new];
         imageView.contentMode = UIViewContentModeScaleAspectFill;
         imageView.layer.masksToBounds = YES ;
         imageView.image = image;
         imageView.frame = fromRect;
         [self.dragContentView addSubview:imageView];
         
         [UIView animateWithDuration:0.2 animations:^{
             imageView.frame = frame;
             self.dragViewBg.alpha = 1;
         }completion:^(BOOL finished) {
             [imageView removeFromSuperview];
             self.topGradient.hidden = NO;
             self.bottomGradient.hidden = NO;
             self.doneBtn.hidden = NO ;
             self.selBtn.hidden = NO ;
             self.selCountLabel.hidden = !self.selCount ;
             self.closeBtn.hidden = NO ;
             self.collectView.hidden = NO;
             self.shouldIgnoreKVO = YES ;
             [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
         }];
     }];
}

#pragma mark -- 点击选择按钮

- (void)selBtnClicked{
    NSString *idString = [self.imageArray safeObjectAtIndex:self.selIndex];
    [[KKPhotoManager sharedInstance]getOriginalImageWithIdentifier:idString
                                                             block:^(KKPhotoInfo *item){
         if(self.selectImageBlock){
             @weakify(self);
             self.selectImageBlock(item, !item.isSelected,self.selIndex,^(BOOL canSelect, NSInteger selCount,NSInteger maxSelCount) {
                 @strongify(self);
                 if(canSelect){
                     self.selBtn.selected = item.isSelected;
                     self.selCount = selCount;
                 }else{
                     [KKKeyWindow promptMessage:[NSString stringWithFormat:@"最多只能选择%ld张图片",maxSelCount] hideDelay:1];
                 }
             });
         }
     }];
}

#pragma mark -- 选中动画

- (void)selectAnimate{
    [UIView animateWithDuration:0.1 animations:^{
        self.selBtn.transform = CGAffineTransformMakeScale(0.9, 0.9);
        self.selCountLabel.transform = CGAffineTransformMakeScale(0.9, 0.9);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.selBtn.transform = CGAffineTransformMakeScale(1.2, 1.2);
            self.selCountLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.selBtn.transform = CGAffineTransformMakeScale(1.0, 1.0);
                self.selCountLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
        }];
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
    KKGalleryPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    cell.conetntImageView.zoomViewDelegate = self;
    NSString *idString = [self.imageArray safeObjectAtIndex:indexPath.row];
    [[KKPhotoManager sharedInstance]getDisplayImageWithIdentifier:idString
                                                    needImageSize:CGSizeMake(2 * UIDeviceScreenWidth, 2 * UIDeviceScreenHeight)
                                                   isNeedDegraded:YES
                                                            block:^(KKPhotoInfo *item)
    {
         cell.image = item.displayImage;
     }];
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
    self.doneBtn.hidden = !self.showView;
    self.selBtn.hidden = !self.showView;
    self.topGradient.hidden = !self.showView;
    self.bottomGradient.hidden = !self.showView;
    if(self.selCount > 0){
        self.selCountLabel.hidden = !self.showView;
    }else{
        self.selCountLabel.hidden = YES;
    }
    [[UIApplication sharedApplication]setStatusBarHidden:!self.showView withAnimation:NO];
}

- (void)imageViewDidZoom:(KKImageZoomView *)zoomView{
    self.enableFreedomDrag = NO ;
}

#pragma mark -- UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    self.enableFreedomDrag = NO ;
    
//    CGPoint offset = self.collectView.contentOffset;
//    CGFloat progress = offset.x / (CGFloat)ImageItemWith;
//    NSInteger index = offset.x / (CGFloat)ImageItemWith;
//
//    //设置上下、当前三张图片的透明度
//    NSInteger nextIndex = index + 1 ;
//    if(nextIndex < self.imageArray.count){
//        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:nextIndex inSection:0]];
//        [cell setAlpha:fabs(progress-index)];
//    }
//
//    KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
//    [cell setAlpha:1 - fabs((progress-index))];
//
//    NSInteger perIndex = index - 1 ;
//    if(perIndex >= 0){
//        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:perIndex inSection:0]];
//        [cell setAlpha:fabs((index - progress))];
//    }
}

//结束拉拽视图
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    CGPoint offset = self.collectView.contentOffset;
    NSInteger index = offset.x / ImageItemWith;
    if(index < 0 || index >= self.imageArray.count){
        return ;
    }
    self.selBtn.selected = [[KKPhotoManager sharedInstance]querySelectStateWithIdentifier:[self.imageArray safeObjectAtIndex:index]];
}

//完全停止滚动
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = self.collectView.contentOffset;
    NSInteger index = offset.x / (CGFloat)ImageItemWith;
    if(index < 0 || index >= self.imageArray.count){
        return ;
    }
    
    self.selIndex = index ;
    
//    KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selIndex inSection:0]];
//    [cell setAlpha:1.0];
//    
    NSInteger nextIndex = self.selIndex + 1 ;
    NSString *idString = [self.imageArray safeObjectAtIndex:nextIndex];
//    if(nextIndex < self.imageArray.count){
//        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:nextIndex inSection:0]];
//        [cell setAlpha:1.0];
//        [cell.conetntImageView setImage:nil];
//    }
    [[KKPhotoManager sharedInstance]clearDisplayImage:idString];
//
    NSInteger perIndex = self.selIndex - 1 ;
    idString = [self.imageArray safeObjectAtIndex:perIndex];
//    if(perIndex >= 0){
//        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:perIndex inSection:0]];
//        [cell setAlpha:1.0];
//        [cell.conetntImageView setImage:nil];
//    }
    [[KKPhotoManager sharedInstance]clearDisplayImage:idString];
    
    self.enableFreedomDrag = NO ;
    
    if(self.imageIndexChangeBlock){
        @weakify(self);
        self.imageIndexChangeBlock(self.selIndex, ^(CGRect oriFrame) {
            @strongify(self);
            self.oriFrame = oriFrame;
        });
    }
    
    self.selBtn.selected = [[KKPhotoManager sharedInstance]querySelectStateWithIdentifier:[self.imageArray safeObjectAtIndex:self.selIndex]];
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
    
    if(self.alphaViewIfNeedBlock){
        self.alphaViewIfNeedBlock(self.enableFreedomDrag&&!self.defaultHideAnimateWhenDragFreedom,self.selIndex);
    }
}

- (void)dragingWithPoint:(CGPoint)pt{
    self.collectView.scrollEnabled = NO ;
    self.collectView.bounces = NO ;
    if(self.enableFreedomDrag){
        self.closeBtn.hidden = YES;
        self.doneBtn.hidden = YES;
        self.selBtn.hidden = YES;
        self.selCountLabel.hidden = YES;
        self.topGradient.hidden = YES;
        self.bottomGradient.hidden = YES;
        
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
            self.closeBtn.hidden = !self.showView;
            self.doneBtn.hidden = !self.showView;
            self.selBtn.hidden = !self.showView;
            self.topGradient.hidden = !self.showView;
            self.bottomGradient.hidden = !self.showView;
            if(self.selCount > 0){
                self.selCountLabel.hidden = !self.showView;
            }else{
                self.selCountLabel.hidden = YES;
            }
            
            [UIView animateWithDuration:0.3 animations:^{
                imageView.layer.transform = CATransform3DIdentity;
            }completion:^(BOOL finished) {
            }];
            
            [[UIApplication sharedApplication]setStatusBarHidden:!self.showView withAnimation:NO];
            
        }else{
            [self hideViewAnimate];
        }
    }else{
        if(self.alphaViewIfNeedBlock){
            self.alphaViewIfNeedBlock(!hideView,self.selIndex);
        }
    }
    
    self.enableFreedomDrag = NO ;
}

#pragma mark -- 消失动画

- (void)hideViewAnimate{
    if(self.zoomAnimateWhenHide){
        KKGalleryPreviewCell *cell = (KKGalleryPreviewCell *)[self.collectView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selIndex inSection:0]];
        KKImageZoomView *view = cell.conetntImageView;
        if(view.zoomScale != view.minimumZoomScale){
            return ;
        }
        
        [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:NO];
        [[UIApplication sharedApplication]setStatusBarStyle:self.barStyle];
        
        UIImageView *imageView = view.imageView;
        imageView.hidden = YES ;
        
        CGRect frame = [self.dragContentView convertRect:imageView.frame toView:self.oriView];
        
        self.dragViewBg.alpha = 0;
        self.dragContentView.hidden = YES;
        
        if(self.hideImageAnimateBlock){
            self.hideImageAnimateBlock(imageView.image,frame,self.oriFrame);
        }
    }else{
        [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:NO];
        [[UIApplication sharedApplication]setStatusBarStyle:self.barStyle];
        [self startHide];
    }
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

#pragma mark -- @property setter

- (void)setSelCount:(NSInteger)selCount{
    _selCount = selCount;
    self.selCountLabel.hidden = !selCount;
    self.selCountLabel.text = [NSString stringWithFormat:@"%ld",selCount];
    [self selectAnimate];
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
            view.hidden = YES ;
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
            //[view setTitle:@"退出" forState:UIControlStateNormal];
            //[view.titleLabel setFont:[UIFont systemFontOfSize:17]];
            //[view setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [view setImage:[UIImage imageNamed:@"close_w_big"] forState:UIControlStateNormal];
            [view addTarget:self action:@selector(hideViewAnimate) forControlEvents:UIControlEventTouchUpInside];
            view.hidden = YES ;
            view ;
        });
    }
    return _closeBtn;
}

- (UILabel *)selCountLabel{
    if(!_selCountLabel){
        _selCountLabel = ({
            UILabel *view = [UILabel new];
            view.textAlignment = NSTextAlignmentCenter;
            view.textColor = [UIColor whiteColor];
            view.backgroundColor = KKColor(0, 140, 218, 1);
            view.font = [UIFont systemFontOfSize:15];
            view.lineBreakMode = NSLineBreakByCharWrapping;
            view.layer.cornerRadius = selCountLabelWH / 2.0 ;
            view.layer.masksToBounds = YES ;
            view.hidden = YES ;
            view ;
        });
    }
    return _selCountLabel;
}

- (UIButton *)doneBtn{
    if(!_doneBtn){
        _doneBtn = ({
            UIButton *view = [UIButton new];
            [view setTitle:@"完成" forState:UIControlStateNormal];
            [view.titleLabel setFont:[UIFont systemFontOfSize:17]];
            [view setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            [view addTarget:self action:@selector(hideViewAnimate) forControlEvents:UIControlEventTouchUpInside];
            [view setHidden:YES];
            view;
        });
    }
    return _doneBtn;
}

- (UIButton *)selBtn{
    if(!_selBtn){
        _selBtn = ({
            UIButton *view = [UIButton new];
            [view setImage:[UIImage imageNamed:@"checkbox-normal-grey"] forState:UIControlStateNormal];
            [view setImage:[UIImage imageNamed:@"checkbox-selected"] forState:UIControlStateSelected];
            [view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            [view addTarget:self action:@selector(selBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            [view setSelected:NO];
            [view setHidden:YES];
            view ;
        });
    }
    return _selBtn;
}

- (CAGradientLayer *)topGradient{
    if(!_topGradient){
        _topGradient = [CAGradientLayer layer];
        _topGradient.colors = @[(__bridge id)[[UIColor blackColor]colorWithAlphaComponent:0.8].CGColor, (__bridge id)[UIColor clearColor].CGColor];
        _topGradient.startPoint = CGPointMake(0, 0);
        _topGradient.endPoint = CGPointMake(0.0, 1.0);
        _topGradient.hidden = YES ;
    }
    return _topGradient;
}

- (CAGradientLayer *)bottomGradient{
    if(!_bottomGradient){
        _bottomGradient = [CAGradientLayer layer];
        _bottomGradient.colors = @[(__bridge id)[[UIColor blackColor]colorWithAlphaComponent:0.8].CGColor, (__bridge id)[UIColor clearColor].CGColor];
        _bottomGradient.startPoint = CGPointMake(0, 1.0);
        _bottomGradient.endPoint = CGPointMake(0.0, 0.0);
        _bottomGradient.hidden = YES ;
    }
    return _bottomGradient;
}

@end
