//
//  WKScrollMenuView.h
//  JanesiBrowser
//
//  Created by mc on 2018/4/26.
//  Copyright © 2018年 weaken. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    WKScrollMenuTypeDefault,  //根据titles的宽度自定义，如果宽度超过最大宽度，
                              // 就选择WKScrollMenuTypeSizeToFit，否则平分
    WKScrollMenuTypeAverage,  //平均分
    WKScrollMenuTypeSizeToFit //根据字体大小适配
} WKScrollMenuType;

@interface WKScrollMenuView : UIView
//当前选中索引,默认0
@property (nonatomic, assign, readonly) NSInteger selectItemIndex;

//默认mainColor
@property (nonatomic, strong) UIColor *selectColor;
//默认999999
@property (nonatomic, strong) UIColor *normalColor;
//默认16
@property (nonatomic, strong) UIFont  *labelFont;
//滑竿尺寸默认{30,3}
@property (nonatomic, assign) CGSize  lineSize;

//按钮间距,会根据imageViewSize和maxImageItemNum自动调整, 默认25
@property (nonatomic, assign) CGFloat   itemMargin;
//图片模式时，图片默认大小，默认为控件高度-10
@property (nonatomic, assign) CGSize    imageViewSize;
//图片模式下单屏幕最多显示数量，默认4个
@property (nonatomic, assign) NSInteger maxImageItemNum;
//左右边距，默认kscale(56)
@property (nonatomic, assign) CGFloat   appendLeftSpace;
//隐藏滑竿
@property (nonatomic, assign) BOOL      hiddenSlider;
//隐藏底部划线
@property (nonatomic, assign) BOOL      hiddenBottomLine;

//点击了按钮的回调
@property (nonatomic, copy  ) void (^ clickItem)(NSInteger index);

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/** 图片模式时，menuItems是一个字典数组，key为‘normal’和‘select’ */
- (instancetype)initWithFrame:(CGRect)frame
                  isImageMenu:(BOOL)isImageMenu
                     menuType:(WKScrollMenuType)menuType
                    menuItems:(NSArray *)menuItems;

- (void)insertMenuItem:(id)menuItem atIndex:(NSInteger)index;
- (void)removeMenuItemAtIndex:(NSInteger)index;
//刷新数据，选中第一个索引
- (void)reloadMenuItems:(NSArray *)menuItems;
//刷新所有item，选中索引不变
- (void)configMenuItems:(NSArray *)menuItems;

//设置line滑杆的进度，(scroll.contentOffset.x / view.width)
- (void)configProgress:(CGFloat)progress;

@end
