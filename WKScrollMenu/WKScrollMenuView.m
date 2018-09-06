//
//  WKScrollMenuView.m
//  JanesiBrowser
//
//  Created by mc on 2018/4/26.
//  Copyright © 2018年 weaken. All rights reserved.
//

#import "WKScrollMenuView.h"

static const CGFloat kMinAverageLabelW = 60;

@interface WKScrollMenuView()
//基本视图
@property (nonatomic, strong) UIView       *bottomLineView;
@property (nonatomic, strong) UIView       *selectLineView;
@property (nonatomic, strong) UIScrollView *itemScrollView;

@property (nonatomic, strong) NSMutableArray<UIView *> *menuViewItems;
@property (nonatomic, strong) UIView                   *selectViewItem;
//配置
@property (nonatomic, assign) BOOL                isImageMenu;
@property (nonatomic, assign) CGFloat             lastX;
@property (nonatomic, assign) CGFloat             standardCenterX;
@property (nonatomic, assign) WKScrollMenuType    menuType;
@property (nonatomic, strong) NSArray             *menuItems;

@end

@implementation WKScrollMenuView

- (instancetype)initWithFrame:(CGRect)frame isImageMenu:(BOOL)isImageMenu menuType:(WKScrollMenuType)menuType menuItems:(NSArray *)menuItems {

    if (self == [super initWithFrame:frame]) {
        
        _lastX           = -1;
        _standardCenterX = -1;
        _lineSize        = CGSizeMake(30, 3);
        _isImageMenu     = isImageMenu;
        _selectColor     = [UIColor redColor];
        
        if (isImageMenu) {
            _imageViewSize = CGSizeMake(frame.size.height - 10, frame.size.height - 10);
            _menuType = WKScrollMenuTypeAverage;
            _maxImageItemNum = 4;
            _appendLeftSpace = 28;
        } else {
            _itemMargin  = 25;
            _normalColor = [UIColor lightGrayColor];
            _labelFont   = [UIFont systemFontOfSize:16];
            _menuType    = menuType;
        }
        
        _menuViewItems = [NSMutableArray array];
        [self setupSubviews];
        [self configMenuItems:menuItems];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _bottomLineView.frame = CGRectMake(0, self.bounds.size.height-0.5, self.bounds.size.width, 1);
    _itemScrollView.frame = self.bounds;
    [self configProgress:self.selectItemIndex];
}

#pragma mark - public
- (void)insertMenuItem:(id)menuItem atIndex:(NSInteger)index {
    if (index >= self.menuItems.count) return;
    
    if (index <= _selectItemIndex) {
        _selectItemIndex += 1;
    }
    NSMutableArray *tmp = [self.menuItems mutableCopy];
    [tmp insertObject:menuItem atIndex:index];
    [self configMenuItems:[tmp copy]];
}
- (void)removeMenuItemAtIndex:(NSInteger)index {
    if (index >= self.menuItems.count) return;

    if (index < _selectItemIndex) {
        _selectItemIndex -= 1;
    } else if (index == _selectItemIndex) {
        _selectItemIndex = 0;
    }
    NSMutableArray *tmp = [self.menuItems mutableCopy];
    [tmp removeObjectAtIndex:index];
    [self configMenuItems:[tmp copy]];
}
- (void)reloadMenuItems:(NSArray *)menuItems {
    _selectItemIndex = 0;
    [self configMenuItems:menuItems];
}

#pragma mark -
//初始化所有子标签的位置以及滑竿位置
- (void)configMenuItems:(NSArray *)menuItems {
    
    _selectViewItem  = nil;
    _standardCenterX = -1;
    _lastX = 0;
    
    if (!_hiddenSlider) {
        self.selectLineView.frame  = CGRectMake(0, 0, _lineSize.width, _lineSize.height);
        self.selectLineView.center = CGPointMake(0, self.bounds.size.height);
    }
    while (self.menuViewItems.count > menuItems.count) {
        [self.menuViewItems.lastObject removeFromSuperview];
        [self.menuViewItems removeLastObject];
    }
    
    /**  图片模式 必须为平分 **/
    if (_isImageMenu) {
        CGFloat totalW = self.frame.size.width - _appendLeftSpace * 2;
        CGFloat itemW = _imageViewSize.width;
        NSInteger itemCount = MIN(_maxImageItemNum, menuItems.count);
        _itemMargin = (totalW - itemCount * itemW) / itemCount;

        for (int i = 0; i < menuItems.count; i++) {
            UIImageView *imageView;
            NSDictionary *dict = [menuItems objectAtIndex:i];
            if (self.menuViewItems.count > i) {
                imageView = (UIImageView *)[self.menuViewItems objectAtIndex:i];
            } else {
                imageView = [UIImageView new];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [self.itemScrollView addSubview:imageView];
                [self.menuViewItems addObject:imageView];
            }
            imageView.frame = CGRectMake(_itemMargin * 0.5 + i * (itemW + _itemMargin) + _appendLeftSpace,
                                         (self.frame.size.height - _imageViewSize.height) * 0.5,
                                         itemW,
                                         _imageViewSize.height);
            
            if (i == self.selectItemIndex) {
                _selectViewItem = imageView;
                self.selectLineView.center = CGPointMake(CGRectGetMidX(_selectViewItem.frame),
                                                         self.frame.size.height - _lineSize.height);
                imageView.image = [UIImage imageNamed:dict[@"select"]];
            } else {
                imageView.image = [UIImage imageNamed:dict[@"normal"]];
            }
        }

        //多出限定数量，需要menu能够滑动
        if (menuItems.count > _maxImageItemNum) {
            CGFloat contentW = self.menuViewItems.lastObject.frame.origin.x + itemW + _itemMargin * 0.5 + _appendLeftSpace;
            self.itemScrollView.contentSize = CGSizeMake(contentW, self.frame.size.height);
            _standardCenterX = self.frame.size.width * 0.5;
        } else {
            self.itemScrollView.contentSize = CGSizeZero;
        }
       
    } else {
        /**  文字模式  **/
        WKScrollMenuType tmpType = self.menuType;
        NSMutableArray *titleWidths = [NSMutableArray arrayWithCapacity:menuItems.count];
        CGFloat totalLabelW = _itemMargin * 0.5 + _appendLeftSpace * 2;//contentSize
        CGFloat maxLabelW = kMinAverageLabelW;
        for (NSString *title in menuItems) {
            CGFloat titleW = [self labelAutoCalculateRectWith:title] + 2;
            [titleWidths addObject:@(titleW)];
            totalLabelW += (titleW + _itemMargin);
            maxLabelW = MAX(maxLabelW, titleW);
        }
        /* 如果是默认模式，判断具体模式: 当子标签长度大于视图长度时，
         需要进行滚动，类型改为根据标签文字长度适配，否则平分 */
        if (_menuType == WKScrollMenuTypeDefault) {
            if (totalLabelW > self.frame.size.width) {
                tmpType = WKScrollMenuTypeSizeToFit;
            } else {
                tmpType = WKScrollMenuTypeAverage;
            }
        }

        //设置title位置
        if (tmpType == WKScrollMenuTypeSizeToFit) {
            CGFloat x = _itemMargin * 0.5 + _appendLeftSpace;
            for (int i = 0; i < menuItems.count; i++) {
                UILabel *label;
                NSString *title = [menuItems objectAtIndex:i];
                CGFloat w = [titleWidths[i] floatValue];
                if (self.menuViewItems.count > i) {
                    label = (UILabel *)[self.menuViewItems objectAtIndex:i];
                }
                else {
                    label = [UILabel new];
                    label.font = self.labelFont;
                    label.textAlignment = NSTextAlignmentCenter;
                    [self.itemScrollView addSubview:label];
                    [self.menuViewItems addObject:label];
                }
                
                if (i == self.selectItemIndex) {
                    _selectViewItem = label;
                    label.textColor = self.selectColor;
                    self.selectLineView.center = CGPointMake(x + w / 2.0, self.bounds.size.height - 3);
                } else {
                    label.textColor = self.normalColor;
                }
                
                label.text = title;
                label.frame = CGRectMake(x, 0, w, self.bounds.size.height-2);
                x += (_itemMargin + w);
            }
            _standardCenterX = self.frame.size.width * 0.5;
            self.itemScrollView.contentSize = CGSizeMake(x - _itemMargin * 0.5 + _appendLeftSpace, 0);
        } else {
            CGFloat averageTotalW = maxLabelW * menuItems.count + 2 * _appendLeftSpace;
            CGFloat itemSpace;
            if (averageTotalW > self.frame.size.width) {//需要进行平分滚动
                itemSpace = _itemMargin;
                averageTotalW = 2 * _appendLeftSpace + (maxLabelW + itemSpace) * menuItems.count;
                _standardCenterX = self.frame.size.width * 0.5;
                self.itemScrollView.scrollEnabled = YES;
            } else {
                itemSpace = (self.frame.size.width - 2 * _appendLeftSpace) / menuItems.count - maxLabelW;
                self.itemScrollView.scrollEnabled = NO;
            }
            self.itemScrollView.contentSize = CGSizeMake(averageTotalW, 0);
            CGFloat itemW = maxLabelW;
            for (int i = 0; i < menuItems.count; i++) {
                UILabel *label;
                NSString *title = [menuItems objectAtIndex:i];
                if (self.menuViewItems.count > i) {
                    label = (UILabel *)[self.menuViewItems objectAtIndex:i];
                } else {
                    label = [UILabel new];
                    label.textAlignment = NSTextAlignmentCenter;
                    [self.itemScrollView addSubview:label];
                    [self.menuViewItems addObject:label];
                }
                label.text = title;
                label.font = self.labelFont;
                label.frame = CGRectMake(_appendLeftSpace + itemSpace * 0.5 + i * (itemW + itemSpace), 0, itemW, self.frame.size.height);
                
                if (i == self.selectItemIndex) {
                    _selectViewItem = label;
                    label.textColor = self.selectColor;
                    self.selectLineView.center = CGPointMake(CGRectGetMidX(label.frame), self.frame.size.height-_lineSize.height);
                } else {
                    label.textColor = self.normalColor;
                }
            }
        }
    }
    
    //根据selectItemIndex进行偏移
    if (!_hiddenSlider) {
        [self.itemScrollView bringSubviewToFront:self.selectLineView];
        if (!menuItems.count) {
            _selectLineView.hidden = YES;
        } else {
            _selectLineView.hidden = NO;
        }
    }
    self.menuItems = menuItems;
    [self scrollViewAutoScroll];
}

- (void)configProgress:(CGFloat)progress {

    if (!self.menuItems.count || progress < 0 || progress > self.menuItems.count - 1) return;
    
    CGFloat centerX = 0;
    CGFloat cutProgress = 0.0;//当前节点到下一节点距离进度0.0~1.0
    
    /** 获取滚动的中点，变更选中的item */
    if (progress > _lastX) {//向右
        
        NSInteger ct = progress;
        NSInteger nt = ct + 1;
        if (self.menuItems.count > ct) {//排除滚动到最后一位，继续滚动的问题
            UIView *cl = self.menuViewItems[ct];//当前item
            CGFloat ncnt;//下一个item的中点位置
            //获取下一个label的中点
            if (self.menuItems.count <= nt) {//下一个item为最后一个item，虚拟出一段可滑动距离_itemMargin
                ncnt = CGRectGetMaxX(cl.frame) + _itemMargin;
                cutProgress = 0;
            } else {
                UIView *nl = self.menuViewItems[nt];
                ncnt = nl.frame.origin.x + nl.frame.size.width / 2.0;
                cutProgress = progress - ct;
            }

            CGFloat ccnt = cl.frame.origin.x + cl.frame.size.width / 2.0;//当前item的重点位置
            //(下一个中点 - 当前中点）/ 总进度(1.0) = 实际滑动中点 / 当前进度(cutProgress)
            centerX = ccnt+(progress-ct)*(ncnt-ccnt);
            //切换选中item
            if ((int)centerX == (int)ccnt && cl != _selectViewItem) {
                [self changSelectStateWithNow:ct];
            }
        }
    }
    else {//向左
        NSInteger ct = progress + 1;
        NSInteger pt = progress;
        
        if (pt >= 0) {
            CGFloat ccnt;
            UIView *pl = self.menuViewItems[pt];
            CGFloat pcnt = pl.frame.origin.x + pl.frame.size.width / 2.0;
            if (ct == self.menuItems.count) {
                ccnt = CGRectGetMaxX(pl.frame) + _itemMargin;
            } else {
                UIView *cl = self.menuViewItems[ct];
                ccnt = cl.frame.origin.x + cl.frame.size.width / 2.0;
            }
            cutProgress = 1 - progress + pt;
            centerX = pcnt+(progress-pt)*(ccnt-pcnt);
            if ((int)centerX == (int)pcnt && _selectViewItem != pl) {
                [self changSelectStateWithNow:pt];
            }
        }
    }
    [self scrollViewAutoScroll];
    _lastX = progress;
    if (!_hiddenSlider) {
        self.selectLineView.center = CGPointMake(centerX, self.bounds.size.height - _lineSize.height);
        if (cutProgress <= 0.5) {
            self.selectLineView.transform = CGAffineTransformMakeScale(1.0 + 1.8 * cutProgress * 2.0, 1.0);
        } else {
            self.selectLineView.transform = CGAffineTransformMakeScale(1.0 + 1.8 * (1 - cutProgress) * 2.0, 1.0);
        }
    }
}

- (void)scrollViewAutoScroll {
    if (_standardCenterX < 0) return;
    
    UIView *cur = self.menuViewItems[self.selectItemIndex];
    CGFloat x = cur.frame.origin.x + cur.frame.size.width / 2.0;
    if (x < _standardCenterX) {//开始到头
        [self.itemScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        return;
    }
    
    if (x + _standardCenterX >= self.itemScrollView.contentSize.width) {//到底
        [self.itemScrollView setContentOffset:CGPointMake(self.itemScrollView.contentSize.width-self.itemScrollView.frame.size.width, 0) animated:YES];
        return;
    }
    
    [self.itemScrollView setContentOffset:CGPointMake(x - _standardCenterX, 0) animated:YES];
}

- (void)tap_itemLab:(UITapGestureRecognizer *)tapper {
    CGPoint loc = [tapper locationInView:self.itemScrollView];
    for (UIView *item in self.menuViewItems) {
        if (CGRectContainsPoint(item.frame, loc)) {
            if (_selectViewItem == item) return;
            NSInteger index = [self.menuViewItems indexOfObject:item];
            [self changSelectStateWithNow:index];
            [self scrollViewAutoScroll];
//            [self configProgress:index];
            if (self.clickItem) {
                self.clickItem(index);
            }
            return;
        }
    }
}

#pragma mark - setup
- (void)setupSubviews {
    _itemScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    _itemScrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:_itemScrollView];

    _bottomLineView = [UIView new];
    _bottomLineView.backgroundColor = [UIColor grayColor];
    [self addSubview:_bottomLineView];
    
    _selectLineView = [UIView new];
    _selectLineView.layer.cornerRadius = _lineSize.height * .5;
    _selectLineView.backgroundColor = _selectColor;
    [_itemScrollView addSubview:_selectLineView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap_itemLab:)];
    tap.delaysTouchesBegan = YES;
    tap.numberOfTapsRequired = 1;
    [self.itemScrollView addGestureRecognizer:tap];
}

#pragma mark - setter
- (void)setLabelFont:(UIFont *)labelFont {
    if (_isImageMenu) return;
    
    _labelFont = labelFont;
    [self configMenuItems:_menuItems];
}
- (void)setLineSize:(CGSize)lineSize {
    _lineSize = lineSize;
    CGPoint center = _selectLineView.center;
    _selectLineView.frame = CGRectMake(0, 0, lineSize.width, lineSize.height);
    _selectLineView.center = center;
    _selectLineView.layer.cornerRadius = lineSize.height * 0.5;
}
- (void)setItemMargin:(CGFloat)itemMargin {
    if (_isImageMenu) return;
    
    _itemMargin = itemMargin;
    [self configMenuItems:_menuItems];
}
- (void)setSelectColor:(UIColor *)selectColor {
    if (_isImageMenu) return;
    
    _selectColor = selectColor;
    ((UILabel *)_selectViewItem).textColor = selectColor;
}
- (void)setNormalColor:(UIColor *)normalColor {
    if (_isImageMenu) return;
    _normalColor = normalColor;
    for (int i = 0; i < self.menuViewItems.count; i++) {
        if (i != self.selectItemIndex) {
            ((UILabel *)self.menuViewItems[i]).textColor = normalColor;
        }
    }
}
- (void)setHiddenSlider:(BOOL)hiddenSlider {
    _hiddenSlider = hiddenSlider;
    _selectLineView.hidden = hiddenSlider;
}
- (void)setImageViewSize:(CGSize)imageViewSize {
    if (CGSizeEqualToSize(imageViewSize, _imageViewSize) || !_isImageMenu) return;
    
    _imageViewSize = imageViewSize;
    [self configMenuItems:_menuItems];
}

- (void)setMaxImageItemNum:(NSInteger)maxImageItemNum {
    if (_maxImageItemNum == maxImageItemNum || !_isImageMenu) return;
    
    _maxImageItemNum = maxImageItemNum;
    [self configMenuItems:_menuItems];
}

- (void)setAppendLeftSpace:(CGFloat)appendLeftSpace {
    if (_appendLeftSpace == appendLeftSpace || !_isImageMenu) return;
    
    _appendLeftSpace = appendLeftSpace;
    [self configMenuItems:_menuItems];
}

- (void)setHiddenBottomLine:(BOOL)hiddenBottomLine {
    _bottomLineView.hidden = hiddenBottomLine;
}

#pragma mark - config
- (CGFloat)labelAutoCalculateRectWith:(NSString *)text {
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary* attributes = @{NSFontAttributeName:_labelFont,
                                 NSParagraphStyleAttributeName:paragraphStyle.copy};
    CGSize labelSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
    labelSize.width = ceil(labelSize.width);
    return labelSize.width;
}

//切换选中item
- (void)changSelectStateWithNow:(NSInteger)now {
    
    UIView *nowItem = self.menuViewItems[now];
    UIView *lastItem = self.selectViewItem;

    if (_isImageMenu) {
        NSDictionary *cdict = self.menuItems[self.selectItemIndex];
        UIImageView *lastV = (UIImageView *)lastItem;
        lastV.image = [UIImage imageNamed:cdict[@"normal"]];
        NSDictionary *pdict = self.menuItems[now];
        ((UIImageView *)nowItem).image = [UIImage imageNamed:pdict[@"select"]];
    } else {
        ((UILabel *)nowItem).textColor = _selectColor;
        ((UILabel *)lastItem).textColor = _normalColor;
    }
    
    _selectItemIndex = now;
    _selectViewItem = nowItem;
}

@end
