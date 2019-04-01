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
        NSLog(@"start");
        [self.imgMgr fetchCameraRollWithOption:nil completion:^(DWAlbumManager * mgr,DWAlbumModel *obj) {
            [mgr fetchPostForAlbum:obj targetSize:CGSizeMake(600, 600) completion:^(DWAlbumManager * mgr,DWImageAssetModel *obj) {
                self.imageView.image = obj.media;
                NSLog(@"end");
            }];
        }];
    }
}


@end
