//
//  DWAlbumListViewController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/8/4.
//

#import "DWAlbumListViewController.h"

@interface DWPosterCell : UITableViewCell<UITraitEnvironment>

@property (nonatomic ,assign) BOOL darkModeEnabled;

@property (nonatomic ,strong) UIImageView * posterImageView;

@property (nonatomic ,strong) UILabel * titleLabel;

@property (nonatomic ,strong) UILabel * countLabel;

@property (nonatomic ,strong) DWAlbumModel * albumModel;

@property (nonatomic ,assign) BOOL darkMode;

@property (nonatomic ,strong) UIColor * internalBlackColor;

@end

@implementation DWPosterCell

#pragma mark --- override ---
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.darkModeEnabled = YES;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"DWImagePickerController" ofType:@"bundle"];
        NSBundle * bundle = [NSBundle bundleWithPath:bundlePath];
        UIImage * image = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"list_indicator@3x" ofType:@"png"]];
        self.accessoryView = [[UIImageView alloc] initWithImage:image];
    }
    return self;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    self.posterImageView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat indicatorMargin = 50;
    CGFloat labelMargin = 10;
    CGRect posterFrm = CGRectMake(0, 0, height, height);
    if (!CGRectEqualToRect(self.posterImageView.frame, posterFrm)) {
        self.posterImageView.frame = posterFrm;
    }
    
    [self.titleLabel sizeToFit];
    CGPoint origin = CGPointMake(height + labelMargin, (height - self.titleLabel.bounds.size.height) * 0.5);
    CGRect titleFrm = self.titleLabel.bounds;
    titleFrm.origin = origin;
    
    BOOL needCountLb = YES;
    if (CGRectGetMaxX(titleFrm) > width - indicatorMargin) {
        CGSize size = titleFrm.size;
        size.width = width - height - labelMargin - indicatorMargin;
        titleFrm.size = size;
        needCountLb = NO;
    } else if (CGRectGetMaxX(titleFrm) > width - indicatorMargin - labelMargin - labelMargin) {
        needCountLb = NO;
    }
    self.titleLabel.frame = titleFrm;
    
    if (needCountLb) {
        [self.countLabel sizeToFit];
        CGPoint origin = CGPointMake(CGRectGetMaxX(titleFrm) + labelMargin, (height - self.countLabel.bounds.size.height) * 0.5);
        CGRect countFrm = self.countLabel.bounds;
        countFrm.origin = origin;
        if (CGRectGetMaxX(countFrm) > width - indicatorMargin - labelMargin) {
            CGSize size = countFrm.size;
            size.width = width - origin.x - indicatorMargin - labelMargin;
            if (size.width <= 0) {
                self.countLabel.hidden = YES;
                return;
            }
            countFrm.size = size;
        }
        self.countLabel.hidden = NO;
        self.countLabel.frame = countFrm;
    } else {
        self.countLabel.hidden = YES;
    }
}

#pragma mark --- UITraitEnvironment ---
-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(8.0)) {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0,*)) {
        [self refreshUserInterfaceStyle];
    }
}

-(void)refreshUserInterfaceStyle API_AVAILABLE(ios(13.0)) {
    self.titleLabel.textColor = self.internalBlackColor;
}

#pragma mark --- setter/getter ---
-(UIImageView *)posterImageView {
    if (!_posterImageView) {
        _posterImageView = [[UIImageView alloc] init];
        _posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        _posterImageView.clipsToBounds = YES;
        [self.contentView addSubview:_posterImageView];
    }
    return _posterImageView;
}

-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _titleLabel.textColor = self.internalBlackColor;
        [self.contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

-(UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:17];
        _countLabel.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:_countLabel];
    }
    return _countLabel;
}

-(void)setDarkModeEnabled:(BOOL)darkModeEnabled {
    if (_darkModeEnabled != darkModeEnabled) {
        _darkModeEnabled = darkModeEnabled;
        if (@available(iOS 13.0,*)) {
            [self refreshUserInterfaceStyle];
        }
    }
}

-(BOOL)darkMode {
    if (self.darkModeEnabled) {
        if (@available(iOS 13.0,*)) {
            if ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    return NO;
}

-(UIColor *)internalBlackColor {
    if (self.darkMode) {
        return [UIColor whiteColor];
    }
    return [UIColor blackColor];
}

@end

@interface DWAlbumListViewController ()<UITraitEnvironment>

@property (nonatomic ,assign) CGFloat cellHeight;

@property (nonatomic ,assign) CGSize photoSize;

///深色模式适配
@property (nonatomic ,assign) BOOL darkMode;

@property (nonatomic ,strong) UIColor * internalBlackColor;

@property (nonatomic ,strong) UIColor * internalWhiteColor;

@end

@implementation DWAlbumListViewController

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        if (self.darkModeEnabled) {
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        } else {
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
    }
    self.cellHeight = 70;
    CGFloat scale = 2;
    self.photoSize = CGSizeMake(self.cellHeight * scale, self.cellHeight * scale);
    self.view.backgroundColor = self.internalWhiteColor;
    self.tableView.backgroundColor = self.internalWhiteColor;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerClass:[DWPosterCell class] forCellReuseIdentifier:@"PosterCell"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark --- tool method ---
-(void)configWithAlbums:(NSArray <DWAlbumModel *>*)albums albumManager:(DWAlbumManager *)albumManager {
    if (![_albums isEqual:albums]) {
        _albums = albums;
        [self.tableView reloadData];
    }
    if (![_albumManager isEqual:albumManager]) {
        _albumManager = albumManager;
    }
}

#pragma mark --- tableView delegate ---
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albums.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DWPosterCell * cell = [tableView dequeueReusableCellWithIdentifier:@"PosterCell" forIndexPath:indexPath];
    DWAlbumModel * albumModel = self.albums[indexPath.row];
    cell.titleLabel.text = albumModel.name;
    cell.countLabel.text = [NSString stringWithFormat:@"(%ld)",(long)albumModel.count];
    cell.albumModel = albumModel;
    [self.albumManager fetchPostForAlbum:albumModel targetSize:self.photoSize completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if ([albumModel isEqual:cell.albumModel]) {
            cell.posterImageView.image = obj.media;
        }
    }];
    [cell setNeedsLayout];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DWAlbumModel * albumModel = self.albums[indexPath.row];
    if (self.albumSelectAction) {
        self.albumSelectAction(albumModel, indexPath);
    }
}

#pragma mark --- UITraitEnvironment ---
-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(8.0)) {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0,*)) {
        [self refreshUserInterfaceStyle];
    }
}

-(void)refreshUserInterfaceStyle API_AVAILABLE(ios(13.0)) {
    self.tableView.backgroundColor = self.internalWhiteColor;
    self.view.backgroundColor = self.internalWhiteColor;
    [self.tableView reloadData];
}

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _darkModeEnabled = YES;
    }
    return self;
}

#pragma mark --- setter/getter ---
-(void)setDarkModeEnabled:(BOOL)darkModeEnabled {
    if (_darkModeEnabled != darkModeEnabled) {
        _darkModeEnabled = darkModeEnabled;
        if (@available(iOS 13.0,*)) {
            [self refreshUserInterfaceStyle];
        }
    }
}

-(BOOL)darkMode {
    if (self.darkModeEnabled) {
        if (@available(iOS 13.0,*)) {
            if ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    return NO;
}

-(UIColor *)internalBlackColor {
    if (self.darkMode) {
        return [UIColor whiteColor];
    }
    return [UIColor blackColor];
}

-(UIColor *)internalWhiteColor {
    if (!self.darkMode) {
        return [UIColor whiteColor];
    }
    return [UIColor blackColor];
}

@end
