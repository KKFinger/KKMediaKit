//
//  KKPhotoAlbumCtrl.m
//  KKPhotoKit
//
//  Created by kkfinger on 2018/7/5.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "KKPhotoAlbumCtrl.h"
#import "KKPhotoManager.h"
#import "KKAlbumCell.h"
#import "KKAppTools.h"
#import "KKBlockAlertView.h"
#import "KKImageGalleryCtrl.h"

static NSString *albumCellIdentifier = @"albumCellIdentifier";

@interface KKPhotoAlbumCtrl ()<UITableViewDataSource,UITableViewDelegate,KKImageGalleryCtrlDelegate>
@property(nonatomic)UITableView *albumTableView;
@property(nonatomic)KKBlockAlertView *alertView;
@property(nonatomic)KKMediaAlbumInfo *albumInfo;
@property(nonatomic,copy)NSString *albumId;
@property(nonatomic)NSMutableArray<KKMediaAlbumInfo *> *albumInfoArray;
@end

@implementation KKPhotoAlbumCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadImageAlbumList];
    [self pushPickerViewWithAlbumId:nil animate:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)dealloc{
    NSLog(@"%@ dealloc------",NSStringFromClass([self class]));
}

#pragma mark -- 设置UI

- (void)setupUI{
    //导航栏遮挡视图的问题
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"照片";
    self.navigationItem.rightBarButtonItem = [KKAppTools createItemWithTitle:@"取消" imageName:nil target:self selector:@selector(quitSelf) isLeft:NO];
    self.navigationController.navigationBar.borderType = KKBorderTypeBottom;
    self.navigationController.navigationBar.borderColor = [[UIColor grayColor]colorWithAlphaComponent:0.1];
    self.navigationController.navigationBar.borderThickness = 0.3;
    self.navigationController.navigationBar.translucent = NO ;
    
    [self.view addSubview:self.albumTableView];
    [self.albumTableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
}

#pragma mark -- 加载相册列表

- (void)loadImageAlbumList{
    [self.view showSysActivityWithStyle:UIActivityIndicatorViewStyleGray];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        KKPhotoAuthorizationStatus status = [[KKPhotoManager sharedInstance]authorizationStatus];
        while (status == KKPhotoAuthorizationStatusNotDetermined) {
            usleep(1.0 * 1000.0);
            status = [[KKPhotoManager sharedInstance]authorizationStatus] ;
        }
        if(status == KKPhotoAuthorizationStatusAuthorized){
            [[KKPhotoManager sharedInstance]getImageAlbumList:^(NSArray<KKMediaAlbumInfo *> *array) {
                [self.albumInfoArray removeAllObjects];
                for(KKMediaAlbumInfo *info in array){
                    if(info.assetCount){
                        [self.albumInfoArray addObject:info];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.view hiddenActivity];
                    [self.albumTableView reloadData];
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

#pragma mark -- UITableViewDelegate,UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1 ;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.albumInfoArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 78 ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KKAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:albumCellIdentifier];
    KKMediaAlbumInfo *info = [self.albumInfoArray safeObjectAtIndex:indexPath.row];
    [cell refreshWith:info curtSelAlbumId:self.albumId cellType:KKAlbumCellImage];
    return cell ;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KKMediaAlbumInfo *info = [self.albumInfoArray safeObjectAtIndex:indexPath.row];
    [self pushPickerViewWithAlbumId:info.albumId animate:YES];
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

#pragma mark -- 显示相片选择视图

- (void)pushPickerViewWithAlbumId:(NSString *)albumId animate:(BOOL)animate{
    KKImageGalleryCtrl *ctrl = [[KKImageGalleryCtrl alloc]initWithAlbumId:albumId];
    ctrl.delegate = self ;
    [self.navigationController pushViewController:ctrl animated:animate];
}

#pragma mark -- KKImageGalleryCtrlDelegate

- (void)selectImageItem:(KKPhotoInfo *)photoItem isSel:(BOOL)isSel complete:(void (^)(BOOL canOperator,BOOL couldContinueSel,NSInteger curtSelCnt,NSInteger maxLimitCnt))complete{
    if(self.delegate && [self.delegate respondsToSelector:@selector(selectImageItem:isSel:complete:)]){
        [self.delegate selectImageItem:photoItem isSel:isSel complete:complete];
    }
}

- (NSInteger)fetchCurrentSelCount{
    if(self.delegate && [self.delegate respondsToSelector:@selector(fetchCurrentSelCount)]){
        return [self.delegate fetchCurrentSelCount];
    }
    return 0 ;
}

- (NSArray *)fetchGallerySelectedArray{
    if(self.delegate && [self.delegate respondsToSelector:@selector(fetchGallerySelectedArray)]){
        return [self.delegate fetchGallerySelectedArray];
    }
    return nil;
}


#pragma mark -- @property

- (UITableView *)albumTableView{
    if(!_albumTableView){
        _albumTableView = ({
            UITableView *view = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
            view.dataSource = self ;
            view.delegate = self ;
            view.separatorStyle = UITableViewCellSeparatorStyleSingleLine ;
            view.separatorColor = [[UIColor grayColor]colorWithAlphaComponent:0.1];
            view.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, UIDeviceScreenWidth, KKSafeAreaBottomHeight)];
            [view registerClass:[KKAlbumCell class] forCellReuseIdentifier:albumCellIdentifier];
            
            //iOS11 reloadData界面乱跳bug
            view.estimatedRowHeight = 0;
            view.estimatedSectionHeaderHeight = 0;
            view.estimatedSectionFooterHeight = 0;
            if(IOS11_OR_LATER){
                KKAdjustsScrollViewInsets(view);
            }
            
            view ;
        });
    }
    return _albumTableView;
}

- (NSMutableArray<KKMediaAlbumInfo *> *)albumInfoArray{
    if(!_albumInfoArray){
        _albumInfoArray = [NSMutableArray<KKMediaAlbumInfo *> new];
    }
    return _albumInfoArray;
}

@end
