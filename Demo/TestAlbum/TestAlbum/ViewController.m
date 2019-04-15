//
//  ViewController.m
//  TestAlbum
//
//  Created by Wicky on 2019/4/15.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWImagePickerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    NSUInteger column = 6;
    CGFloat spacing = 0.5;
    CGFloat cellWidth = ([UIScreen mainScreen].bounds.size.width - (column - 1) * spacing) / column;
    layout.minimumLineSpacing = spacing;
    layout.minimumInteritemSpacing = spacing;
    layout.itemSize = CGSizeMake(cellWidth, cellWidth);
    
    DWImagePickerViewController * imagePicker = [[DWImagePickerViewController alloc] initWithCollectionViewLayout:layout];
    [self presentViewController:imagePicker animated:YES completion:nil];
}



@end
