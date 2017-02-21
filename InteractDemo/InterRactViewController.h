//
//  InterRactViewController.h
//  SF
//
//  Created by admin on 2017/1/13.
//  Copyright © 2017年 Focus Technology Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InterRactViewController : UIViewController
@property (nonatomic, assign) CGFloat tabBarWidth;

/**
 *  设置 content vc
 */
- (void)setInterRactContentViewController:(UIViewController *)contentViewController;

/**
 *  移除 content vc
 */
- (void)removeInterRactContentViewController;

/**
 *  点击关闭按钮触发的事件和切换 tab 触发
 */
- (void)closeInteractView;

/**
 *  显示此 view
 */
- (void)showInteractView;

/**
 *  设置折叠起来的标题的 view
 *
 *  @param contentFoldView  折叠起来的 title view
 *  @param title  此 view 的 title
 *  @param againStr 重新作答的 title，如果传 nil 或者空值，则隐藏
 */
- (void)setContentTitleFoldViewForRunTime:(UIView *)contentFoldView
                                    title:(NSString *)title
                                againText:(NSString *)againStr;

/**
 *  获取当前vc 的内容 vc
 */
- (UIViewController *)getInteractContentVc;

/**
 *  当显示互动窗口时候点击背景的动画
 */
- (void)animateWhenClickBgView;
@end


