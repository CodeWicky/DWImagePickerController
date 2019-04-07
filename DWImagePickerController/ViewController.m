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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imgMgr = [[DWAlbumManager alloc] init];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([self.imgMgr authorizationStatus] != 3) {
        [self.imgMgr requestAuthorization:^(PHAuthorizationStatus status) {
            NSLog(@"%ld",status);
        }];
    } else if (self.album) {
        printf("start %f\n",[[NSDate date] timeIntervalSince1970] * 1000);
        [self.imgMgr fetchOriginImageWithAlbum:self.album index:2 progress:nil completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
            printf("end %f\n",[[NSDate date] timeIntervalSince1970] * 1000);
            self.imageView.image = obj.media;
        }];
    } else {
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
}


@end
