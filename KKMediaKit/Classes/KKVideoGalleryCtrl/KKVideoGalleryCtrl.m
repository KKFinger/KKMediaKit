//
//  KKVideoGalleryCtrl.m
//  KKMediaKit
//
//  Created by kkfinger on 2019/2/13.
//  Copyright © 2019 kkfinger. All rights reserved.
//

#import "KKVideoGalleryCtrl.h"
#import "KKVideoManager.h"
#import "KKBlockAlertView.h"
#import "KKAppTools.h"
#import "KKGalleryVideoCell.h"
#import <MediaPlayer/MediaPlayer.h>

static NSString *cellReuseIdentifier = @"videoCellReuseIdentifier";
static CGFloat space = 1.0 ;

@interface KKVideoGalleryCtrl ()<UICollectionViewDelegate,UICollectionViewDataSource>
@property(nonatomic)UICollectionView *collectView;
@property(nonatomic)KKBlockAlertView *alertView;
@property(nonatomic,assign)CGFloat cellWH;
@property(nonatomic,assign)CGSize imageSize;
@property(nonatomic,copy)NSString *albumId;
@property(nonatomic)NSMutableArray<KKVideoInfo *> *videoInfoArray;
@end

@implementation KKVideoGalleryCtrl

- (instancetype)initWithAlbumId:(NSString *)albumId{
    self = [super init];
    if(self){
        self.albumId = albumId ;
    }
    return self ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupParam];
    [self initUI];
    [self loadAlbumInfoWithAlbumId];
}

#pragma mark -- 设置参数

- (void)setupParam{
    self.videoInfoArray = [NSMutableArray<KKVideoInfo *> arrayWithCapacity:0];
    self.imageSize = CGSizeMake(130, 130);
    self.cellWH = (UIDeviceScreenWidth - 2 * space ) / 3.0;
    if(!self.albumId.length){
        self.albumId = [[KKVideoManager sharedInstance]getCameraRollAlbumId];
    }
}

#pragma mark -- 初始化UI

- (void)initUI{
    [self.view addSubview:self.collectView];
    [self.collectView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
}

#pragma mark -- 加载视频

- (void)loadAlbumInfoWithAlbumId{
    [self.view showActivityViewWithTitle:nil];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        KKPhotoAuthorizationStatus status = [[KKVideoManager sharedInstance]authorizationStatus];
        while (status == KKPhotoAuthorizationStatusNotDetermined) {
            usleep(1.0 * 1000.0);
            status = [[KKVideoManager sharedInstance]authorizationStatus] ;
        }
        if(status == KKPhotoAuthorizationStatusAuthorized){
            if(self.albumId == nil){
                self.albumId = [[KKVideoManager sharedInstance]getCameraRollAlbumId];
            }
            [[KKVideoManager sharedInstance]initAlbumWithAlbumObj:self.albumId block:^(BOOL done, KKMediaAlbumInfo *albumInfo) {
                [[KKVideoManager sharedInstance]getVideoInfoListWithBlock:^(BOOL suc, NSArray<KKVideoInfo *> *infoArray) {
                    [self.videoInfoArray removeAllObjects];
                    if(infoArray.count){
                        [self.videoInfoArray addObjectsFromArray:infoArray];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.collectView reloadData];
                        [self.view hiddenActivity];
                    });
                }];
            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                KKBlockAlertView *view = [KKBlockAlertView new];
                [view showWithTitle:@"相册权限" message:@"没有相册权限" cancelButtonTitle:@"知道了" otherButtonTitles:@"去设置" block:^(NSInteger re_code, NSDictionary *userInfo) {
                    if(re_code == 1){
                        [KKAppTools jumpToAppSetting];
                    }
                }];
                self.alertView = view ;
                [self.view hiddenActivity];
            });
        }
    });
}

#pragma mark -- UICollectionViewDelegate,UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.videoInfoArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    KKGalleryVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    KKVideoInfo *videoInfo = [self.videoInfoArray safeObjectAtIndex:indexPath.row];
    [cell refreshCell:videoInfo];
    [[KKVideoManager sharedInstance]getVideoCorverWithIndex:indexPath.row needImageSize:self.imageSize isNeedDegraded:YES block:^(KKVideoInfo *videoInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.corverImage = videoInfo.videoCorver;
        });
    }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.cellWH, self.cellWH);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    KKVideoInfo *videoInfo = [self.videoInfoArray safeObjectAtIndex:indexPath.row];
    [self playWithVideoInfo:videoInfo];
}

//设置水平间距 (同一行的cell的左右间距）
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return space;
}

//垂直间距 (同一列cell上下间距)
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return space;
}

#pragma mark -- 视频播放

- (void)playWithVideoInfo:(KKVideoInfo *)videoInfo{
    NSURL *url = [NSURL fileURLWithPath:videoInfo.filePath];
    MPMoviePlayerViewController *ctrl = [[MPMoviePlayerViewController alloc]initWithContentURL:url];
    [self presentViewController:ctrl animated:YES completion:nil];
}

#pragma mark -- @property

- (UICollectionView *)collectView{
    if(!_collectView){
        _collectView = ({
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
            UICollectionView *view = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
            view.delegate= self;
            view.dataSource= self;
            view.backgroundColor = [UIColor whiteColor];
            [view registerClass:[KKGalleryVideoCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
            view;
        });
    }
    return _collectView;
}

@end
