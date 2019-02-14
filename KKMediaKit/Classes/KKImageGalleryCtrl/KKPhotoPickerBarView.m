//
//  KKPhotoPickerBarView.m
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/16.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "KKPhotoPickerBarView.h"

static CGFloat selCountLabelWH = 17 ;

@interface KKPhotoPickerBarView()
@property(nonatomic)UIButton *previewBtn;
@property(nonatomic)UIButton *doneBtn;
@property(nonatomic)UILabel *selCountLabel;
@end

@implementation KKPhotoPickerBarView

- (instancetype)init{
    self = [super init];
    if(self){
        [self setupUI];
    }
    return self ;
}

#pragma mark -- 设置UI

- (void)setupUI{
    [self addSubview:self.previewBtn];
    [self addSubview:self.doneBtn];
    [self addSubview:self.selCountLabel];
    [self.previewBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).mas_offset(-KKSafeAreaBottomHeight/2.0);
        make.left.mas_equalTo(self).mas_offset(KKPaddingLarge);
        make.size.mas_equalTo(CGSizeMake(70, 40));
    }];
    [self.doneBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).mas_offset(-KKSafeAreaBottomHeight/2.0);
        make.right.mas_equalTo(self.selCountLabel.mas_left).mas_offset(-5);
        make.size.mas_equalTo(CGSizeMake(70, 40));
    }];
    [self.selCountLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).mas_offset(-KKSafeAreaBottomHeight/2.0);
        make.right.mas_equalTo(self).mas_offset(-KKPaddingLarge);
        make.size.mas_equalTo(CGSizeMake(selCountLabelWH, selCountLabelWH));
    }];
    self.selectCount = 0 ;
}

#pragma mark -- 预览

- (void)preViewClicked{
    if(self.delegate && [self.delegate respondsToSelector:@selector(previewSelectedImages)]){
        [self.delegate previewSelectedImages];
    }
}

#pragma mark -- 完成按钮

- (void)doneBtnClicked{
    if(self.delegate && [self.delegate respondsToSelector:@selector(doneSelectedImages)]){
        [self.delegate doneSelectedImages];
    }
}

#pragma mark -- 选中动画

- (void)selectAnimate{
    [UIView animateWithDuration:0.1 animations:^{
        self.selCountLabel.transform = CGAffineTransformMakeScale(0.9, 0.9);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.selCountLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.selCountLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
        }];
    }];
}

#pragma mark -- @property setter

- (void)setSelectCount:(NSInteger)selectCount{
    _selectCount = selectCount ;
    
    [self.doneBtn setEnabled:selectCount>0];
    [self.doneBtn setAlpha:selectCount>0?1.0:0.5];
    [self.doneBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.selCountLabel.mas_left).mas_offset((selectCount <= 0) ? 0 : -5);
    }];
    
    [self.previewBtn setEnabled:selectCount>0];
    [self.previewBtn setAlpha:selectCount>0?1.0:0.5];
    
    [self.selCountLabel setHidden:(selectCount<=0)];
    [self.selCountLabel setText:[NSString stringWithFormat:@"%ld",selectCount]];
    [self.selCountLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo((selectCount <= 0) ? CGSizeZero : CGSizeMake(selCountLabelWH, selCountLabelWH));
    }];
    
    [self selectAnimate];
}

#pragma mark -- @property getter

- (UIButton *)previewBtn{
    if(!_previewBtn){
        _previewBtn = ({
            UIButton *view = [UIButton new];
            [view setTitleColor:[[UIColor blackColor]colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
            [view setTitleColor:KKColor(0, 140, 218, 1) forState:UIControlStateNormal];
            [view setTitle:@"预览" forState:UIControlStateNormal];
            [view setTitle:@"预览" forState:UIControlStateDisabled];
            [view.titleLabel setFont:[UIFont systemFontOfSize:16]];
            [view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [view setEnabled:NO];
            [view addTarget:self action:@selector(preViewClicked) forControlEvents:UIControlEventTouchUpInside];
            view;
        });
    }
    return _previewBtn;
}

- (UIButton *)doneBtn{
    if(!_doneBtn){
        _doneBtn = ({
            UIButton *view = [UIButton new];
            [view setTitleColor:[[UIColor blackColor]colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
            [view setTitleColor:KKColor(0, 140, 218, 1) forState:UIControlStateNormal];
            [view setTitle:@"完成" forState:UIControlStateNormal];
            [view setTitle:@"完成" forState:UIControlStateDisabled];
            [view.titleLabel setFont:[UIFont systemFontOfSize:16]];
            [view setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            [view setEnabled:NO];
            [view addTarget:self action:@selector(doneBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            view;
        });
    }
    return _doneBtn;
}

- (UILabel *)selCountLabel{
    if(!_selCountLabel){
        _selCountLabel = ({
            UILabel *view = [UILabel new];
            view.textAlignment = NSTextAlignmentCenter;
            view.textColor = [UIColor whiteColor];
            view.backgroundColor = KKColor(0, 140, 218, 1);
            view.font = [UIFont systemFontOfSize:13];
            view.lineBreakMode = NSLineBreakByCharWrapping;
            view.layer.cornerRadius = selCountLabelWH / 2.0 ;
            view.layer.masksToBounds = YES ;
            view.hidden = YES ;
            view ;
        });
    }
    return _selCountLabel;
}

@end
