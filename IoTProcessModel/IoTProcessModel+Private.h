/**
 * IoTProcessModel+Private.h
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

#ifndef IoTProcessModel_IoTProcessModel_Private_h
#define IoTProcessModel_IoTProcessModel_Private_h

#import <MBProgressHUD/MBProgressHUD.h>
#import "IoTStepFrame.h"

typedef enum
{
    IoTAccountTypeGuest,
    IoTAccountTypeDefault,//电话和邮箱都一样
}IoTAccountType;

@interface IoTProcessModel()
{
    NSMutableArray *stepFrames;
}

@property (readonly, nonatomic, strong) MBProgressHUD *hud;

/**
 * @brief 设备
 */
@property (nonatomic, strong) NSString *product;
@property (nonatomic, strong) NSString *subProduct;

/**
 * @brief 用户信息
 */
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *token;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, assign) IoTAccountType accountType;

@property (nonatomic, assign) BOOL isRegisteredUser;

/**
 * @brief 公共方法
 */
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)imageWithFileName:(NSString *)filename bundle:(NSBundle *)bundle;
+ (UIImage *)imageWithFileName:(NSString *)filename;//bundle 省略则使用 [IoTProcessModel resourceBundle]
+ (NSBundle *)resourceBundle;

/**
 * @brief 定好的步骤
 */
+ (NSArray *)generalSteps;
+ (NSArray *)softAPSteps;

@property (nonatomic, strong, readonly) NSArray *stepFrames;

- (void)addStepFrame:(IoTStepFrame *)stepFrame;
- (void)removeStepFrame:(IoTStepFrame *)stepFrame;

@end

#endif
