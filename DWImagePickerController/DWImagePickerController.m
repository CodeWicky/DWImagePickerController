//
//  DWImagePickerController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/12.
//  Copyright © 2019 Wicky. All rights reserved.
//



#import "DWImagePickerController.h"
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumGridViewController.h"
#import "DWAlbumListViewController.h"

@interface DWImagePickerController ()

@property (nonatomic ,strong) DWAlbumGridViewController * gridVC;

@property (nonatomic ,strong) DWAlbumListViewController * listVC;

@property (nonatomic ,strong) DWMediaPreviewController * previewVC;

@end

@implementation DWImagePickerController
@synthesize albumManager = _albumManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark --- interface method ---
-(instancetype)initWithAlbumManager:(DWAlbumManager *)albumManager option:(DWAlbumFetchOption *)opt columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing {
    if (self = [super init]) {
        _albumManager = albumManager;
        _fetchOption = opt;
        _columnCount = columnCount;
        _spacing = spacing;
    }
    return self;
}

-(void)fetchCameraRollWithCompletion:(dispatch_block_t)completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.albumManager fetchAlbumsWithOption:self.fetchOption completion:^(DWAlbumManager * _Nullable mgr, NSArray<DWAlbumModel *> * _Nullable obj) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.listVC configWithAlbums:obj albumManager:self.albumManager];
                [self.gridVC configWithAlbum:obj.firstObject albumManager:self.albumManager];
                [self setViewControllers:@[self.listVC,self.gridVC]];
                if (completion) {
                    completion();
                }
            });
        }];
    });
}

+(instancetype)showImagePickerWithAlbumManager:(DWAlbumManager *)albumManager option:(DWAlbumFetchOption *)opt currentVC:(UIViewController *)currentVC {
    if (!currentVC) {
        return nil;
    }
    DWImagePickerController * imagePicker = [((DWImagePickerController *)[self alloc]) initWithAlbumManager:albumManager option:opt columnCount:4 spacing:0.5];
    [imagePicker fetchCameraRollWithCompletion:^{
        [currentVC presentViewController:imagePicker animated:YES completion:nil];
    }];
    return imagePicker;
}

#pragma mark --- tool method ---
-(void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark --- setter/getter ---
-(DWAlbumListViewController *)listVC {
    if (!_listVC) {
        _listVC = [[DWAlbumListViewController alloc] init];
        [_listVC configWithGridVC:self.gridVC];
        _listVC.title = @"照片";
        _listVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _listVC.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
        _listVC.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
        _listVC.navigationItem.backBarButtonItem.tintColor = [UIColor blackColor];
    }
    return _listVC;
}

-(DWAlbumGridViewController *)gridVC {
    if (!_gridVC) {
        CGFloat width = ([UIScreen mainScreen].bounds.size.width - (_columnCount - 1) * _spacing) / _columnCount;
        _gridVC = [[DWAlbumGridViewController alloc] initWithItemWidth:width];
        [_gridVC configWithPreviewVC:self.previewVC];
        self.previewVC.dataSource = _gridVC;
        _gridVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _gridVC.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
        _gridVC.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
        _gridVC.navigationItem.backBarButtonItem.tintColor = [UIColor blackColor];
    }
    return _gridVC;
}

-(DWMediaPreviewController *)previewVC {
    if (!_previewVC) {
        _previewVC = [[DWMediaPreviewController alloc] init];
        _previewVC.closeOnSlidingDown = NO;
    }
    return _previewVC;
}

-(DWAlbumManager *)albumManager {
    if (!_albumManager) {
        _albumManager = [[DWAlbumManager alloc] init];
    }
    return _albumManager;
}
@end
