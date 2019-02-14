//
//  KKVideoAlbumCtrl.m
//  KKMediaKit
//
//  Created by kkfinger on 2019/2/13.
//  Copyright © 2019 kkfinger. All rights reserved.
//

#import "KKVideoAlbumCtrl.h"
#import "KKBlockAlertView.h"
#import "KKVideoManager.h"
#import "KKMediaAlbumInfo.h"
#import "KKAlbumCell.h"
#import "KKVideoGalleryCtrl.h"

static NSString *albumCellIdentifier = @"albumCellIdentifier";

@interface KKVideoAlbumCtrl ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic)UITableView *albumTableView;
@property(nonatomic)KKBlockAlertView *alertView;
@property(nonatomic)KKMediaAlbumInfo *albumInfo;
@property(nonatomic,copy)NSString *albumId;
@property(nonatomic)NSMutableArray<KKMediaAlbumInfo *> *albumInfoArray;
@end

@implementation KKVideoAlbumCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadVideoAlbumList];
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
    
    self.navigationItem.title = @"视频";
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

#pragma mark -- 加载视频列表

- (void)loadVideoAlbumList{
    [self.view showActivityViewWithTitle:nil];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        KKPhotoAuthorizationStatus status = [[KKVideoManager sharedInstance]authorizationStatus];
        while (status == KKPhotoAuthorizationStatusNotDetermined) {
            usleep(1.0 * 1000.0);
            status = [[KKVideoManager sharedInstance]authorizationStatus] ;
        }
        if(status == KKPhotoAuthorizationStatusAuthorized){
            [[KKVideoManager sharedInstance]getVideoAlbumListWithBlock:^(NSArray<KKMediaAlbumInfo *> *albumList) {
                [self.albumInfoArray removeAllObjects];
                for(KKMediaAlbumInfo *info in albumList){
                    if(info.assetCount){
                        [self.albumInfoArray addObject:info];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.albumTableView reloadData];
                    [self.view hiddenActivity];
                });
            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view hiddenActivity];
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
    [cell refreshWith:info curtSelAlbumId:self.albumId cellType:KKAlbumCellVideo];
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
    KKVideoGalleryCtrl *ctrl = [[KKVideoGalleryCtrl alloc]initWithAlbumId:albumId];
    [self.navigationController pushViewController:ctrl animated:animate];
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
