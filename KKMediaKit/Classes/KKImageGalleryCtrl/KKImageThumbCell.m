//
//  KKImageThumbCell.m
//  KKPhotoKit
//
//  Created by finger on 2017/10/22.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKImageThumbCell.h"

static NSInteger gifLabelHeight = 30 ;

@interface KKImageThumbCell()
@property(nonatomic,readwrite)UIView *contentBgView;
@property(nonatomic)UIButton *operatorBtn;
@property(nonatomic)UIButton *operatorBtnMask;
@property(nonatomic)UIButton *lbButton;//左下角的按钮，点击后显示全屏预览
@property(nonatomic,readwrite)UIImageView *imageView;
@property(nonatomic)UIView *disableView;
@property(nonatomic)UILabel *gifLabel;
//@property(nonatomic,strong)CAGradientLayer *topGradient;
@property(nonatomic,assign)KKImageThumbCellType cellType;
@property(nonatomic)KKPhotoInfo *item;
@end

@implementation KKImageThumbCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
//    [CATransaction begin];
//    [CATransaction setDisableActions:YES];
//    self.topGradient.frame = self.bounds;
//    [CATransaction commit];
}

#pragma mark -- 设置UI

- (void)setupUI{
    [self.contentView addSubview:self.contentBgView];
    [self.contentView addSubview:self.disableView];
    [self.contentBgView addSubview:self.imageView];
    [self.contentBgView addSubview:self.operatorBtn];
    [self.contentBgView addSubview:self.operatorBtnMask];
    [self.contentBgView addSubview:self.lbButton];
    [self.contentBgView addSubview:self.gifLabel];
    //[self.contentBgView.layer insertSublayer:self.topGradient below:self.operatorBtn.layer];
    
    [self.contentBgView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.contentView);
    }];
    
    [self.disableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.contentView);
    }];
    
    [self.operatorBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.contentBgView).mas_offset(3);
        make.right.mas_equalTo(self.contentBgView).mas_offset(-3);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    }];
    
    [self.operatorBtnMask mas_updateConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.operatorBtn);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    [self.imageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.contentBgView);
    }];
    
    [self.lbButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.mas_equalTo(self.contentBgView);
        make.size.mas_equalTo(CGSizeMake(50, 50));
    }];
    
    [self.gifLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.mas_equalTo(self.contentBgView).mas_offset(-5);
        make.width.mas_equalTo(25);
    }];
}

#pragma mark -- 操作

- (void)operatorBtnClicked{
    if(self.cellType == KKImageThumbCellTypeDelete){
        if(self.delegate && [self.delegate respondsToSelector:@selector(deleteImage:photoItem:)]){
            [self.delegate deleteImage:self photoItem:self.item];
        }
    }else{
        if(self.delegate && [self.delegate respondsToSelector:@selector(selectImage:photoItem:)]){
            [self.delegate selectImage:self photoItem:self.item];
        }
    }
}

#pragma mark -- 刷新界面

- (void)refreshCell:(KKPhotoInfo *)item cellType:(KKImageThumbCellType)type disable:(BOOL)disable{
    self.item = item ;
    self.cellType = type;
    self.operatorBtn.hidden = (item.photoType == KKPhotoInfoTypePlaceholderImage) ;
    self.operatorBtnMask.hidden = (item.photoType == KKPhotoInfoTypePlaceholderImage) ;
    self.gifLabel.hidden = !item.isGif;
    //self.topGradient.hidden = (item.photoType == KKPhotoInfoTypePlaceholderImage);
    if(type == KKImageThumbCellTypeDelete ||
       type == KKImageThumbCellTypeEdit){
        //[self.operatorBtn setImage:[UIImage imageNamed:@"delete_black"] forState:UIControlStateNormal];
        //[self.operatorBtn setImage:[UIImage imageNamed:@"delete_black"] forState:UIControlStateSelected];
        [self.operatorBtn setImage:nil forState:UIControlStateNormal];
        [self.operatorBtn setImage:nil forState:UIControlStateSelected];
        [self.operatorBtn setSelected:NO];
    }else{
        [self.operatorBtn setImage:[UIImage imageNamed:@"checkbox-normal-grey"] forState:UIControlStateNormal];
        [self.operatorBtn setImage:[UIImage imageNamed:@"checkbox-selected"] forState:UIControlStateSelected];
        [self.operatorBtn setSelected:item.isSelected];
    }
    
    if(item.photoType == KKPhotoInfoTypeCamera ||
       item.photoType == KKPhotoInfoTypeGallery ||
       item.photoType == KKPhotoInfoTypePlaceholderImage){
        self.imageView.image = item.thumbImage;
    }else{
        [self.imageView setImageWithUrl:item.thumbUrl placeholder:[UIImage imageWithColor:[UIColor grayColor]] circleImage:NO animate:YES];
    }

    self.disable = disable;
}

#pragma mark -- 点击左下角的按钮

- (void)lbBtnClicked{
    if(self.delegate && [self.delegate respondsToSelector:@selector(showPreviewView:)]){
        [self.delegate showPreviewView:self];
    }
}

#pragma mark -- 选中动画

- (void)selectAnimate{
    [UIView animateWithDuration:0.1 animations:^{
        self.operatorBtn.transform = CGAffineTransformMakeScale(0.9, 0.9);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.operatorBtn.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.operatorBtn.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
        }];
    }];
}

#pragma mark -- @property setter

- (void)setDisable:(BOOL)disable{
    if(disable){
        self.disableView.hidden = NO;
        self.userInteractionEnabled = NO ;
    }else{
        self.disableView.hidden = YES ;
        self.userInteractionEnabled = YES ;
    }
}

#pragma mark -- @property getter

- (UIView *)contentBgView{
    if(!_contentBgView){
        _contentBgView = ({
            UIView *view = [UIView new];
            view ;
        });
    }
    return _contentBgView;
}

- (UIButton *)operatorBtn{
    if(!_operatorBtn){
        _operatorBtn = ({
            UIButton *view = [UIButton new];
            [view addTarget:self action:@selector(operatorBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            [view setSelected:NO];
            [view.imageView setClipsToBounds:YES];
            view ;
        });
    }
    return _operatorBtn;
}

- (UIButton *)operatorBtnMask{
    if(!_operatorBtnMask){
        _operatorBtnMask = ({
            UIButton *view = [UIButton new];
            [view addTarget:self action:@selector(operatorBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            view ;
        });
    }
    return _operatorBtnMask;
}

- (UIButton *)lbButton{
    if(!_lbButton){
        _lbButton = ({
            UIButton *view = [UIButton new];
            [view addTarget:self action:@selector(lbBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            view ;
        });
    }
    return _lbButton;
}

- (UIImageView *)imageView{
    if(!_imageView){
        _imageView = ({
            UIImageView *view = [UIImageView new];
            view.layer.masksToBounds = YES ;
            view.contentMode = UIViewContentModeScaleAspectFill;
            view ;
        });
    }
    return _imageView;
}

- (UIView *)disableView{
    if(!_disableView){
        _disableView = ({
            UIView *view = [UIView new];
            view.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
            view.hidden = YES ;
            view.userInteractionEnabled = NO ;
            view ;
        });
    }
    return _disableView;
}

- (UILabel *)gifLabel{
    if(!_gifLabel){
        _gifLabel = ({
            UILabel *view = [UILabel new];
            view.font = [UIFont systemFontOfSize:13];
            view.layer.cornerRadius = 3 ;
            view.layer.masksToBounds = YES ;
            view.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
            view.textColor = [UIColor whiteColor];
            view.textAlignment = NSTextAlignmentCenter;
            view.text = @"GIF";
            view ;
        });
    }
    return _gifLabel;
}

//- (CAGradientLayer *)topGradient{
//    if(!_topGradient){
//        _topGradient = [CAGradientLayer layer];
//        _topGradient.colors = @[(__bridge id)[[UIColor blackColor]colorWithAlphaComponent:0.3].CGColor, (__bridge id)[UIColor clearColor].CGColor];
//        _topGradient.startPoint = CGPointMake(0, 0);
//        _topGradient.endPoint = CGPointMake(0.0, 1.0);
//    }
//    return _topGradient;
//}

@end
