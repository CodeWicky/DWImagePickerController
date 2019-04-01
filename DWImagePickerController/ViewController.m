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
    } else {
        DWAlbumFetchOption * opt = [[DWAlbumFetchOption alloc] init];
        opt.sortType = DWAlbumSortTypeCreationDateDesending;
        [self.imgMgr fetchAlbumsWithOption:nil completion:^(NSArray<PHFetchResult *> * _Nonnull obj) {
            
//            [obj enumerateObjectsUsingBlock:^(PHAsset * asset, NSUInteger idx, BOOL * _Nonnull stop) {
//                [self.imgMgr fetchOriginImageWithAsset:asset progress:nil completion:^(UIImage * _Nonnull image, NSDictionary * _Nonnull info) {
//                    NSLog(@"%@",NSStringFromCGSize(image.size));
//                    self.imageView.image = image;
//
//                }];
//                *stop = YES;
//            }];
        }];
//        [self.imgMgr fetchCameraRollWithOption:nil completion:^(PHFetchResult * obj) {
//            [obj enumerateObjectsUsingBlock:^(PHAsset * asset, NSUInteger idx, BOOL * _Nonnull stop) {
//                [self.imgMgr fetchOriginImageWithAsset:asset progress:nil completion:^(UIImage * _Nonnull image, NSDictionary * _Nonnull info) {
//                    NSLog(@"%@",NSStringFromCGSize(image.size));
//                    self.imageView.image = image;
//
//                }];
//                *stop = YES;
//            }];
//        }];
    }
}


@end
