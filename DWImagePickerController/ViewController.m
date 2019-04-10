//
//  ViewController.m
//  DWAlbumPickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWAlbumManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic ,strong) DWAlbumManager * imgMgr;

@property (nonatomic ,strong) DWAlbumModel * album;

@property (nonatomic ,assign) int step;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imgMgr = [[DWAlbumManager alloc] init];
    self.step = 0;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    switch (self.step) {
        case 0:
        {
            [self.imgMgr requestAuthorization:^(PHAuthorizationStatus status) {
                NSLog(@"%ld",status);
            }];
        }
            break;
        case 1:
        {
            DWAlbumFetchOption * opt = [[DWAlbumFetchOption alloc] init];
            opt.sortType = DWAlbumSortTypeCreationDateAscending;
            opt.mediaType = DWAlbumMediaTypeAll;
            [self.imgMgr fetchAlbumsWithOption:opt completion:^(DWAlbumManager *mgr, NSArray<DWAlbumModel *> *obj) {
                for (DWAlbumModel * model in obj) {
                    if (model.mediaType == DWAlbumMediaTypeAll || model.mediaType == DWAlbumFetchAlbumTypeCameraRoll) {
                        self.album = model;
                        printf("start %f\n",[[NSDate date] timeIntervalSince1970] * 1000);
                        
                        [mgr fetchImageWithAlbum:model index:2 targetSize:(CGSize)CGSizeMake(160, 160) progress:nil completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
                            printf("end %f\n",[[NSDate date] timeIntervalSince1970] * 1000);
                            self.imageView.image = obj.media;
                        }];
                        break;
                    }
                }
            }];
        }
            break;
        case 2:
        {
            printf("start %f\n",[[NSDate date] timeIntervalSince1970] * 1000);
            [self.imgMgr fetchOriginImageWithAlbum:self.album index:2 progress:nil completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
                printf("end %f\n",[[NSDate date] timeIntervalSince1970] * 1000);
                self.imageView.image = obj.media;
            }];
        }
            break;
        case 3:
        {
            UIImage * image = [UIImage imageNamed:@"icon"];
            [self.imgMgr saveImage:image toAlbum:@"Hello" location:nil createIfNotExist:YES completion:^(DWAlbumManager * _Nullable mgr, DWAssetModel * _Nullable asset, NSError * _Nullable error) {
                NSLog(@"%@",asset);
            }];
        }
            break;
        case 4:
        {
            NSString * path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
            NSURL * url = [NSURL fileURLWithPath:path];
            [self.imgMgr saveVideoToCameraRoll:url completion:^(DWAlbumManager * _Nullable mgr, __kindof DWAssetModel * _Nullable obj, NSError * _Nullable error) {
                NSLog(@"%@",obj);
            }];
        }
            break;
        default:
            break;
    }
    self.step ++;
}


@end
