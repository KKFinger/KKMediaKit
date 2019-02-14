//
//  KKPhotoViewController.m
//  KKPhotoKit
//
//  Created by kkfinger on 2019/2/12.
//  Copyright © 2019 kkfinger. All rights reserved.
//

#import "KKPhotoViewController.h"
#import "KKPhotoGirdPickerView.h"
#import "KKPhotoAlbumCtrl.h"
#import "KKPhotoManager.h"
#import "KKVideoAlbumCtrl.h"

@interface KKPhotoViewController ()<KKPhotoAlbumCtrlDelegate,KKPhotoGirdPickerViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(nonatomic,readwrite)KKPhotoGirdPickerView *contentView;
@property(nonatomic,weak)UIImagePickerController *pickerController;
@property(nonatomic)UIButton *videoBtn;
@end

@implementation KKPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark -- 设置UI

- (void)setupUI{
    [self.view addSubview:self.contentView];
    [self.view addSubview:self.videoBtn];
    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.centerY.mas_equalTo(self.view);
        make.height.mas_equalTo(0);
    }];
    [self.videoBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view).mas_offset(-60);
        make.size.mas_equalTo(CGSizeMake(88, 44));
    }];
}

#pragma mark -- KKPhotoAlbumCtrlDelegate

- (void)selectImageItem:(KKPhotoInfo *)info isSel:(BOOL)isSel complete:(void (^)(BOOL canOperator,BOOL couldContinueSel,NSInteger curtSelCnt,NSInteger maxLimitCnt))complete{
    __block NSInteger curtSel = [self.contentView curtSelPhotoCount];
    NSInteger maxCnt = [self.contentView maxSelPhotoCount];
    if(isSel){
        BOOL canOperator = (curtSel < maxCnt);
        if(canOperator){
            [[KKPhotoManager sharedInstance]getDisplayImageWithIdentifier:info.identifier
                                                            needImageSize:CGSizeMake(2 * UIDeviceScreenWidth, 2 * UIDeviceScreenHeight)
                                                           isNeedDegraded:NO
                                                                    block:^(KKPhotoInfo *item)
             {
                 [info setDisplayImage:item.displayImage];//选择一个相片时,同时设置他的全屏预览相片，方便未全部上传完成时的预览功能
             }];
            [self.contentView addPhotoItem:info];
            curtSel ++ ;
            BOOL couldContinueSel = (curtSel < maxCnt);
            if(complete){
                complete(canOperator,couldContinueSel,curtSel,maxCnt);
            }
        }else{
            BOOL couldContinueSel = (curtSel < maxCnt);
            if(complete){
                complete(canOperator,couldContinueSel,curtSel,maxCnt);
            }
        }
    }else{
        [self.contentView removePhotoItem:info];
        curtSel -- ;
        if(complete){
            complete(YES,YES,curtSel,maxCnt);
        }
    }
}

- (NSInteger)fetchCurrentSelCount{
    return [self.contentView curtSelPhotoCount];
}

- (NSArray *)fetchGallerySelectedArray{
    return [self.contentView fetchGallerySelectedArray];
}

#pragma mark -- KKQuestionContentViewDelegate

- (void)showImageActionSheetView{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    @weakify(self);
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self showTakePhotoView];
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        KKPhotoAlbumCtrl *ctrl = [KKPhotoAlbumCtrl new];
        ctrl.delegate = self ;
        UINavigationController *navCtrl = [[UINavigationController alloc]initWithRootViewController:ctrl];
        [[KKAppTools presentedCttl:self]presentViewController:navCtrl animated:YES completion:nil];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel picker image");
    }];
    
    [actionSheet addAction:action1];
    [actionSheet addAction:action2];
    [actionSheet addAction:actionCancel];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *ctrl = [KKAppTools presentedCttl:self];
        [ctrl presentViewController:actionSheet animated:YES completion:nil];
    });
}

#pragma mark -- 拍照视图

- (void)showTakePhotoView{
    [self.view showSysActivityWithStyle:UIActivityIndicatorViewStyleGray];
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc]init];
    pickerController.delegate = self;
    pickerController.allowsEditing = NO;
    pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.pickerController = pickerController;
    
    UIViewController *ctrl = [KKAppTools presentedCttl:self];
    
    if ([[[UIDevice currentDevice] systemVersion]floatValue] >= 8.0) {
        ctrl.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    
    @weakify(self);
    [ctrl presentViewController:pickerController animated:YES completion:^{
        @strongify(self);
        [self.view hiddenActivity];
    }];
}

#pragma mark -- UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:^{}];
    [KKKeyWindow showActivityViewWithTitle:@"图片压缩中..."];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //UIImage *image = [UIImage imageWithData:[UIImage compressImage:info[UIImagePickerControllerOriginalImage] toByte:4 * 1024 * 1024 quality:1.0]];
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        KKPhotoInfo *item = [KKPhotoInfo new];
        item.identifier = [[NSUUID UUID]UUIDString];
        item.thumbImage = [UIImage compressImage:image quality:1.0 size:CGSizeMake(120, 120)];
        item.displayImage = [UIImage compressImage:image quality:1.0 size:CGSizeMake(2 * UIDeviceScreenWidth, 2 * UIDeviceScreenHeight)];
        item.photoType = KKPhotoInfoTypeCamera ;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger curtSel = [self.contentView curtSelPhotoCount];
            NSInteger maxCnt = [self.contentView maxSelPhotoCount];
            BOOL canAdd = (curtSel < maxCnt);
            if(canAdd){
                [self.contentView addPhotoItem:item];
            }
            [KKKeyWindow hiddenActivity];
        });
    });
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.pickerController dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark -- 显示视频视图

- (void)showVideoGallery{
    KKVideoAlbumCtrl *ctrl = [KKVideoAlbumCtrl new];
    [self.navigationController pushViewController:ctrl animated:YES];
}

#pragma mark -- @property

- (KKPhotoGirdPickerView *)contentView{
    if(!_contentView){
        _contentView = ({
            KKPhotoGirdPickerView *view = [KKPhotoGirdPickerView new];
            view.delegate = self ;
            @weakify(self);
            [view setWidgetHeightChanged:^(CGFloat height) {
                @strongify(self);
                [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(height);
                }];
            }];
            view;
        });
    }
    return _contentView;
}

- (UIButton *)videoBtn{
    if(!_videoBtn){
        _videoBtn = ({
            @weakify(self);
            UIButton *view = [UIButton new];
            [view setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [view setTitle:@"视频" forState:UIControlStateNormal];
            [view.titleLabel setFont:[UIFont systemFontOfSize:15]];
            [view addTapGestureWithBlock:^(UIView *gestureView) {
                @strongify(self);
                [self showVideoGallery];
            }];
            view ;
        });
    }
    return _videoBtn;
}

@end
