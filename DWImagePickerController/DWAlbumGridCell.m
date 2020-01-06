//
//  DWAlbumGridCell.m
//  DWCheckBox
//
//  Created by Wicky on 2020/1/6.
//

#import "DWAlbumGridCell.h"
#import <DWKit/DWLabel.h>

@interface DWAlbumGridCell ()

@property (nonatomic ,strong) UIImageView * gridImage;

@property (nonatomic ,strong) UILabel * durationLabel;

@property (nonatomic ,strong) DWLabel * selectionLb;

@end

@implementation DWAlbumGridCell

-(void)setupDuration:(NSTimeInterval)duration {
    self.durationLabel.hidden = NO;
    NSInteger floorDuration = floor(duration + 0.5);
    NSInteger sec = floorDuration % 60;
    NSInteger min = floorDuration / 60;
    self.durationLabel.text = [NSString stringWithFormat:@"%ld:%02ld",(long)min,(long)sec];
    [self setNeedsLayout];
}

-(void)setSelectAtIndex:(NSInteger)index {
    if (index > 0) {
        self.selectionLb.backgroundColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
        self.selectionLb.layer.borderColor = [UIColor whiteColor].CGColor;
        self.selectionLb.text = [NSString stringWithFormat:@"%ld",(long)index];
    } else {
        self.selectionLb.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        self.selectionLb.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        self.selectionLb.text = nil;
    }
    [self setNeedsLayout];
}

#pragma mark --- override ---
-(void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.gridImage.frame, self.bounds)) {
        self.gridImage.frame = self.bounds;
    }
    if (_durationLabel && !_durationLabel.hidden) {
        [self.durationLabel sizeToFit];
        CGPoint origin = CGPointMake(5, self.bounds.size.height - 5 - self.durationLabel.bounds.size.height);
        CGRect frame = self.durationLabel.frame;
        frame.origin = origin;
        if (!CGRectEqualToRect(self.durationLabel.frame, frame)) {
            self.durationLabel.frame = frame;
        }
    }
    
    if (_selectionLb && !_selectionLb.hidden) {
        [self.selectionLb sizeToFit];
        CGPoint origin = CGPointMake(self.bounds.size.width - self.selectionLb.bounds.size.width - 5, 5);
        CGRect frame = self.selectionLb.frame;
        frame.origin = origin;
        if (!CGRectEqualToRect(self.selectionLb.frame, frame)) {
            self.selectionLb.frame = frame;
        }
    }
}

-(void)prepareForReuse {
    [super prepareForReuse];
    self.gridImage.image = nil;
    _durationLabel.text = nil;
    _durationLabel.hidden = YES;
}

#pragma mark --- setter/getter ---
-(void)setModel:(DWImageAssetModel *)model {
    _model = model;
    self.gridImage.image = model.media;
    if (model.mediaType == PHAssetMediaTypeVideo) {
        [self setupDuration:model.asset.duration];
    }
}

-(UIImageView *)gridImage {
    if (!_gridImage) {
        _gridImage = [[UIImageView alloc] initWithFrame:self.bounds];
        _gridImage.contentMode = UIViewContentModeScaleAspectFill;
        _gridImage.clipsToBounds = YES;
        [self.contentView addSubview:_gridImage];
    }
    return _gridImage;
}

-(UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.font = [UIFont systemFontOfSize:12];
        _durationLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_durationLabel];
    }
    return _durationLabel;
}

-(DWLabel *)selectionLb {
    if (!_selectionLb) {
        _selectionLb = [[DWLabel alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        _selectionLb.minSize = CGSizeMake(22, 22);
        _selectionLb.font = [UIFont systemFontOfSize:13];
        _selectionLb.adjustsFontSizeToFitWidth = YES;
        _selectionLb.textColor = [UIColor whiteColor];
        _selectionLb.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        _selectionLb.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        _selectionLb.layer.borderWidth = 2;
        _selectionLb.layer.cornerRadius = 11;
        _selectionLb.layer.masksToBounds = YES;
        _selectionLb.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_selectionLb];
    }
    return _selectionLb;
}

@end
