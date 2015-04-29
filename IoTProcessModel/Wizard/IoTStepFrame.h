/**
 * IoTStepFrame.h
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

@class IoTStepFrame;

@interface UIViewController(IoTStepFrameExtend)

@property (nonatomic, assign, readonly) IoTStepFrame *stepFrame;

@end

@interface IoTStepFrame : UIViewController

- (id)initWithRootViewController:(UIViewController *)controller;

@property (readonly, nonatomic, strong) UINavigationController *navCtrl;

/**
 * @brief 设置步骤
 * @note 格式：@[
 * @{@"image":img1, @"text": @"text1",
 *   @"frames": @{@"image":location1, @"text": location2}},
 * @{@"image":img2, @"text": @"text2", 
 *   @"frames": @{@"image":location1, @"text": location2}}, ...]
 */
@property (nonatomic, strong) NSArray *steps;

/**
 * @brief 设置当前步骤索引
 * @param 范围即为 steps 的有效范围
 */
@property (nonatomic, assign) NSInteger currentStepIndex;

/**
 * @brief 退出 Step 模式
 */
- (void)cancel:(BOOL)animated;

/**
 * @brief 退出 Step 模式，并跳转到其他控制器
 */
- (void)cancelTo:(UIViewController *)controller animated:(BOOL)animated;

/**
 * @brief 不退出当前的 Step 模式，并跳转到其他控制器
 */
- (void)nextTo:(UIViewController *)controller animated:(BOOL)animated;

@end
