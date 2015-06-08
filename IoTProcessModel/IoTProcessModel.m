/**
 * IoTProcessModel.m
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


static IoTProcessModel *sharedModel = nil;

@implementation IoTProcessModel

+ (IoTProcessModel *)sharedModel
{
    if(nil == sharedModel)
    {
        sharedModel = [[IoTProcessModel alloc] init_internal__];
    }
    return sharedModel;
}

+ (BOOL)copyDataToDocument:(NSString *)product data:(NSData *)data
{
    // 拷贝配置内容到 /Documents/XPGWifiSDK/Devices 目录
    NSString *destPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    destPath = [destPath stringByAppendingPathComponent:@"XPGWifiSDK/Devices"];
    
    // 创建目录
    [[NSFileManager defaultManager] createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    destPath = [destPath stringByAppendingFormat:@"/%@.json", product];
    
    // 把文件复制到指定的目录
    if(![[NSFileManager defaultManager] fileExistsAtPath:destPath])
    {
        if(![data writeToFile:destPath atomically:YES])
            return NO;
    }
    return YES;
}

- (void)initWifiSDK:(NSString *)appid
{
    // 初始化 Wifi SDK
    [XPGWifiSDK startWithAppID:appid];
    
    // 为 Soft AP 模式设置 SSID 名。如果没设置，默认值是 XPG-GAgent, XPG_GAgent
    // [XPGWifiSDK registerSSIDs:@"XPG-GAgent", @"XPG_GAgent", nil];
    
    // 设置日志分级、日志输出文件、是否打印二进制数据
    [XPGWifiSDK setLogLevel:XPGWifiLogLevelAll logFile:@"logfile.txt" printDataLevel:YES];
    
    // 检测 SDK 是否加载成功
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        sleep(1);
        if(![XPGWifiSDK sharedInstance])
        {
            //SDK加载失败
            abort();
        }
    });
    
    //每次初始化 SDK 的时候，重新登录一次
    if(self.isRegisteredUser)
    {
        [self login];
    }
}

+ (IoTProcessModel *)startWithAppID:(NSString *)appid product:(NSString *)product productJson:(NSData *)data
{
    if(appid.length == 0 || product.length == 0 || data.length == 0)
    {
        NSLog(@"startWithAppID failed: Invalid param");
        return nil;
    }
    
    IoTProcessModel *result = ProcessModel;
    if(result)
    {
        // 拷贝配置内容到 /Documents/Devices 目录
        if(![IoTProcessModel copyDataToDocument:product data:data])
        {
            NSLog(@"Can't copy file to /Documents/Devices");
            return nil;
        }
        
        ProcessModel.product = product;
        
        // 初始化 Wifi SDK
        [ProcessModel initWifiSDK:appid];
    }
    return result;
}

+ (IoTProcessModel *)startWithAppID:(NSString *)appid withCentralProducts:(NSDictionary *)products
{
    if(appid.length == 0 || ![products isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"startWithAppID failed: Invalid param");
        return nil;
    }
    
    IoTProcessModel *result = ProcessModel;
    if(result)
    {
        // 拷贝配置内容到 /Documents/Devices 目录
        NSDictionary *centralDevice = products[@"CentralDevice"];
        NSDictionary *subDevice = products[@"SubDevice"];
        
        NSString *centralProduct = centralDevice[@"ProductKey"];
        NSData *centralData = centralDevice[@"Data"];
        
        NSString *subProduct = subDevice[@"ProductKey"];
        NSData *subData = subDevice[@"Data"];
        
        if(centralProduct.length == 0 || centralData.length == 0 ||
           subProduct.length == 0 || subData.length == 0)
        {
            NSLog(@"startWithAppID failed: invalid products");
            return nil;
        }
        
        if([centralProduct isEqualToString:subProduct] || [centralData isEqualToData:subData])
        {
            NSLog(@"startWithAppID failed: central product can't equal to sub product");
            return nil;
        }
        
        if(![IoTProcessModel copyDataToDocument:centralProduct data:centralData])
        {
            NSLog(@"Can't copy central device file to /Documents/Devices");
            return nil;
        }
        
        if(![IoTProcessModel copyDataToDocument:subProduct data:subData])
        {
            NSLog(@"Can't copy sub device file to /Documents/Devices");
            return nil;
        }
        
        ProcessModel.product = centralProduct;
        ProcessModel.subProduct = subProduct;
        
        // 初始化 Wifi SDK
        [ProcessModel initWifiSDK:appid];
    }
    return result;
}

// 读取文件 IoTProcessModule.bundle
+ (NSBundle *)resourceBundle
{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"IoTProcessModule" ofType:@"bundle"];
    NSBundle *ret = [NSBundle bundleWithPath:bundlePath];
    if(nil == ret)
    {
        NSLog(@"warning: inavlid bundle:%@ path:%@", ret, bundlePath);
    }
    return ret;
}

+ (NSArray *)generalSteps
{
    CGRect frame1 = CGRectZero;
    CGRect frame2 = CGRectZero;
    CGRect frame3 = CGRectZero;
    CGRect frame4 = CGRectZero;
    
    if([UIApplication sharedApplication].keyWindow.frame.size.width == 320)
    {
        frame1 = CGRectMake(50, 47, 295, 21);
        frame2 = CGRectMake(102, 47, 295, 21);
        frame3 = CGRectMake(166, 47, 295, 21);
        frame4 = CGRectMake(243, 47, 295, 21);
    }
    
    UIImage *imgStep1 = [IoTProcessModel imageWithFileName:@"step"];
    UIImage *imgStep2 = [IoTProcessModel imageWithFileName:@"step-08"];
    UIImage *imgStep3 = [IoTProcessModel imageWithFileName:@"step-13"];
    UIImage *imgStep4 = [IoTProcessModel imageWithFileName:@"step-15"];
    
    return @[
             @{@"image": imgStep1, @"text": @"注册", @"frames": @{@"text": [NSValue valueWithCGRect:frame1]}},
             @{@"image": imgStep2, @"text": @"搜索设备", @"frames": @{@"text": [NSValue valueWithCGRect:frame2]}},
             @{@"image": imgStep3, @"text": @"输入密码", @"frames": @{@"text": [NSValue valueWithCGRect:frame3]}},
             @{@"image": imgStep4, @"text": @"配置", @"frames": @{@"text": [NSValue valueWithCGRect:frame4]}}
             ];
}

+ (NSArray *)softAPSteps
{
    CGRect frame1 = CGRectZero;
    CGRect frame2 = CGRectZero;
    
    if([UIApplication sharedApplication].keyWindow.frame.size.width == 320)
    {
        frame1 = CGRectMake(86, 47, 295, 21);
        frame2 = CGRectMake(166, 47, 295, 21);
    }
    
    UIImage *imgStep1 = [IoTProcessModel imageWithFileName:@"step-17"];
    UIImage *imgStep2 = [IoTProcessModel imageWithFileName:@"step-18"];
    
    return @[
             @{@"image": imgStep1, @"text": @"选择设备热点", @"frames": @{@"text": [NSValue valueWithCGRect:frame1]}},
             @{@"image": imgStep2, @"text": @"输入密码", @"frames": @{@"text": [NSValue valueWithCGRect:frame2]}}
             ];
}

- (id)init_internal__
{
    self = [super init];
    if(self)
    {
        stepFrames = [NSMutableArray array];
        initPasswordField();
    }
    return self;
}

- (void)login
{
    // 自动登录的方法，如果此项目不支持匿名登录，用宏屏蔽
    // 其他同理
    [XPGWifiSDK sharedInstance].delegate = self;
    
    switch (ProcessModel.accountType) {
#if 0
        case IoTUserTypeAnonymous:
            [[XPGWifiSDK sharedInstance] userLoginAnonymous];
            break;
#endif
        case IoTAccountTypeDefault:
            [[XPGWifiSDK sharedInstance] userLoginWithUserName:ProcessModel.username password:ProcessModel.password];
            break;
        default:
            if([self.delegate respondsToSelector:@selector(IoTProcessModelDidLogin:)])
                [self.delegate IoTProcessModelDidLogin:XPGWifiError_GENERAL];
            NSLog(@"Error: can't supported other login methods");
            break;
    }
}

#pragma mark - Properties
- (MBProgressHUD *)hud
{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.window];
    if(nil == hud)
    {
        hud = [[MBProgressHUD alloc] initWithWindow:self.window];
        [self.window addSubview:hud];
    }
    return hud;
}

#define DefaultSetValue(key, value) \
[[NSUserDefaults standardUserDefaults] setValue:value forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];

#define DefaultGetValue(key) \
[[NSUserDefaults standardUserDefaults] valueForKey:key];

#define IoTConfigKey(x) \
[NSString stringWithFormat:@"IoTConfig%@", x]

#define IOT_CONFIG_USERNAME         IoTConfigKey(@"UserName")
#define IOT_CONFIG_PASSWORD         IoTConfigKey(@"Password")
#define IOT_CONFIG_UID              IoTConfigKey(@"Uid")
#define IOT_CONFIG_TOKEN            IoTConfigKey(@"Token")
#define IOT_CONFIG_ACCOUNTYPE       IoTConfigKey(@"AccountType")

- (void)setUsername:(NSString *)username
{
    DefaultSetValue(IOT_CONFIG_USERNAME, username);
}

- (void)setPassword:(NSString *)password
{
    DefaultSetValue(IOT_CONFIG_PASSWORD, password);
}

- (NSString *)username
{
    return DefaultGetValue(IOT_CONFIG_USERNAME)
}

- (NSString *)password
{
    return DefaultGetValue(IOT_CONFIG_PASSWORD)
}

- (void)setUid:(NSString *)uid
{
    DefaultSetValue(IOT_CONFIG_UID, uid)
}

- (void)setAccountType:(IoTAccountType)accountType
{
    DefaultSetValue(IOT_CONFIG_ACCOUNTYPE, @(accountType))
}

- (void)setToken:(NSString *)token
{
    DefaultSetValue(IOT_CONFIG_TOKEN, token)
}

- (NSString *)uid
{
    return DefaultGetValue(IOT_CONFIG_UID)
}

- (NSString *)token
{
    return DefaultGetValue(IOT_CONFIG_TOKEN)
}

- (IoTAccountType)accountType
{
    NSNumber *nAnymous = DefaultGetValue(IOT_CONFIG_ACCOUNTYPE)
    if(nil != nAnymous)
        return (IoTAccountType)[nAnymous intValue];
    return IoTAccountTypeGuest;
}

- (BOOL)isRegisteredUser
{
    return (self.uid.length > 0 && self.token.length > 0);
}

#pragma mark - Controllers
- (IoTLogin *)loginController
{
    return [[IoTLogin alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
}

- (IoTDeviceList *)deviceListController
{
    return [[IoTDeviceList alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
}


#pragma mark - Common Methods
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageWithFileName:(NSString *)filename bundle:(NSBundle *)bundle
{
    if(nil == bundle)
        bundle = [NSBundle mainBundle];
    NSString *path = nil;
    
    //3x
    if([[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)])
    {
        CGFloat scale = [UIScreen mainScreen].nativeScale;
        if(nil == path)
            path = [bundle pathForResource:[filename stringByAppendingFormat:@"@%ix", (int)scale] ofType:@"png"];
    }
    
    //2x
    if(nil == path)
        path = [bundle pathForResource:[filename stringByAppendingString:@"@2x"] ofType:@"png"];
    
    //最后，找 1x 的图片
    if(nil == path)
         path = [bundle pathForResource:filename ofType:@"png"];
    
    return [UIImage imageWithContentsOfFile:path];
}

+ (UIImage *)imageWithFileName:(NSString *)filename
{
    return [self imageWithFileName:filename bundle:[IoTProcessModel resourceBundle]];
}

#pragma mark - Account Manager
- (NSString *)currentUser
{
    return self.username;
}

- (NSString *)currentUid
{
    return self.uid;
}

- (NSString *)currentToken
{
    return self.token;
}

- (void)logout
{
    [XPGWifiSDK sharedInstance].delegate = self;
    [[XPGWifiSDK sharedInstance] userLogout:ProcessModel.uid];
}

#pragma mark Step Frame
- (NSArray *)stepFrames
{
    return [NSArray arrayWithArray:stepFrames];
}

- (void)addStepFrame:(IoTStepFrame *)stepFrame
{
    if([stepFrames indexOfObject:stepFrame] < stepFrames.count)
        return;
    [stepFrames addObject:stepFrame];
}

- (void)removeStepFrame:(IoTStepFrame *)stepFrame
{
    if([stepFrames indexOfObject:stepFrame] < stepFrames.count)
        [stepFrames removeObject:stepFrame];
}

#pragma mark Account Validates
- (BOOL)validatePhone13:(NSString *)phone
{
    NSString *regex = @"13\\d{9}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:phone];
}

- (BOOL)validatePhone15:(NSString *)phone
{
    NSString *regex = @"15\\d{9}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:phone];
}

- (BOOL)validatePhone17:(NSString *)phone
{
    NSString *regex = @"17\\d{9}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:phone];
}

- (BOOL)validatePhone18:(NSString *)phone
{
    NSString *regex = @"18\\d{9}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:phone];
}

- (BOOL)validatePhone:(NSString *)phone
{
    return [self validatePhone13:phone] ||
    [self validatePhone15:phone] ||
    [self validatePhone17:phone] ||
    [self validatePhone18:phone];
}

- (BOOL)validateEmailFormat:(NSString *)email
{
    NSString *regex = @"\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:email];
}

- (BOOL)validateEmail:(NSString *)email
{
    return [self validateEmailFormat:email] &&
    ([email hasSuffix:@".com"] ||
     [email hasSuffix:@".cn"] ||
     [email hasSuffix:@".net"] ||
     [email hasSuffix:@".com.cn"]);
}

- (BOOL)validatePassword:(NSString *)password
{
    NSString *regex = @"^[\\x10-\\x1f\\x21-\\x7f]+$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:password];
}

#pragma mark - XPGWifiSDKDelegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    // 登录成功，自动设置相关信息
    int nErr = [error intValue];
    NSLog(@"-----------------------> UserLogin result:%d", nErr);
    if (nErr || uid.length == 0 || token.length == 0) {
        NSLog(@"-----------------------> UserLogin errorMassage:%@", errorMessage);
    } else {
        NSLog(@"-----------------------> UserLogin uid:%@ token:%@", uid, token);
        ProcessModel.uid = uid;
        ProcessModel.token = token;
    }
    
    // 回调到外面
    if ([self.delegate respondsToSelector:@selector(IoTProcessModelDidLogin:)])
        [self.delegate IoTProcessModelDidLogin:nErr];
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogout:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    if([error integerValue] == 0)
    {
        ProcessModel.username = nil;
        ProcessModel.password = nil;
        ProcessModel.uid = nil;
        ProcessModel.token = nil;
        ProcessModel.accountType = IoTAccountTypeGuest;
    }
    if([self.delegate respondsToSelector:@selector(IoTProcessModelDidUserLogout:)])
        [self.delegate IoTProcessModelDidUserLogout:error.integerValue];
}

@end

