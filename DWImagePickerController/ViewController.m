//
//  ViewController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWImageManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic ,strong) DWImageManager * imgMgr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imgMgr = [[DWImageManager alloc] init];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([self.imgMgr authorizationStatus] != 3) {
        [self.imgMgr requestAuthorization:^(PHAuthorizationStatus status) {
            NSLog(@"%ld",status);
        }];
    } else {
        DWImageFetchOption * opt = [[DWImageFetchOption alloc] init];
        opt.sortType = DWImageSortTypeCreationDateDesending;
        [self.imgMgr fetchCameraRollWithOption:nil completion:^(PHFetchResult * obj) {
            CGSize targetSize = CGSizeMake(300 * [UIScreen mainScreen].scale, 300 * [UIScreen mainScreen].scale);
            [obj enumerateObjectsUsingBlock:^(PHAsset * asset, NSUInteger idx, BOOL * _Nonnull stop) {
                [self.imgMgr fetchImageWithAsset:asset targetSize:targetSize completion:^(UIImage * _Nonnull image, NSDictionary * _Nonnull info) {
                    NSLog(@"%@",NSStringFromCGSize(image.size));
                    self.imageView.image = image;
                    
                }];
                *stop = YES;
            }];
        }];
    }
    
}


@end
