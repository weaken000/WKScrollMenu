//
//  ViewController.m
//  WKScrollMenuDemo
//
//  Created by mac on 2018/9/6.
//  Copyright © 2018年 weikun. All rights reserved.
//

#import "ViewController.h"
#import "WKScrollMenuView.h"

@interface ViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong) WKScrollMenuView *scrollMenu_sizeToFit;

@property (nonatomic, strong) WKScrollMenuView *scrollMenu_average;

@property (nonatomic, strong) WKScrollMenuView *scrollMenu_image;


@property (nonatomic, strong) UIScrollView     *scrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat top = [UIApplication sharedApplication].statusBarFrame.size.height;
    _scrollMenu_sizeToFit = [[WKScrollMenuView alloc] initWithFrame:CGRectMake(0, top, self.view.frame.size.width, 60) isImageMenu:NO menuType:WKScrollMenuTypeSizeToFit menuItems:@[@"标题标题标题1", @"标题标题标题2", @"标题3", @"标题4", @"标题标题5", @"标题标题6"]];
    [self.view addSubview:_scrollMenu_sizeToFit];
    
    _scrollMenu_average = [[WKScrollMenuView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_scrollMenu_sizeToFit.frame), self.view.frame.size.width, 60) isImageMenu:NO menuType:WKScrollMenuTypeAverage menuItems:@[@"标题1", @"标题2", @"标题3", @"标题4", @"标题5", @"标题6"]];
    [self.view addSubview:_scrollMenu_average];
    
    NSMutableArray *tmp = [NSMutableArray array];
    for (int i = 1; i < 7; i++) {
        NSString *normal = [NSString stringWithFormat:@"home_nav_icon%d", i];
        NSString *select = [NSString stringWithFormat:@"home_nav_icon%d-%d", i, i];
        [tmp addObject:@{@"normal": normal,
                         @"select": select}];

    }
    _scrollMenu_image = [[WKScrollMenuView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_scrollMenu_average.frame), self.view.frame.size.width, 80) isImageMenu:YES menuType:WKScrollMenuTypeDefault menuItems:tmp];
    _scrollMenu_image.appendLeftSpace = 0;
    [self.view addSubview:_scrollMenu_image];
    
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_scrollMenu_image.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetMaxY(_scrollMenu_image.frame))];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width * 6, 0);
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
    
    __weak typeof(self) weakSelf = self;
    _scrollMenu_sizeToFit.clickItem = ^(NSInteger index) {
        [weakSelf.scrollView setContentOffset:CGPointMake(index * weakSelf.view.frame.size.width, 0) animated:YES];
    };
    _scrollMenu_average.clickItem = ^(NSInteger index) {
        [weakSelf.scrollView setContentOffset:CGPointMake(index * weakSelf.view.frame.size.width, 0) animated:YES];
    };
    _scrollMenu_image.clickItem = ^(NSInteger index) {
        [weakSelf.scrollView setContentOffset:CGPointMake(index * weakSelf.view.frame.size.width, 0) animated:YES];
    };
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat progress = scrollView.contentOffset.x / scrollView.frame.size.width;
    [_scrollMenu_average configProgress:progress];
    [_scrollMenu_image configProgress:progress];
    [_scrollMenu_sizeToFit configProgress:progress];
}



@end
