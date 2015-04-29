/**
 * IoTRegisterByPhone.m
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

#import "IoTRegisterByPhone.h"
#import "IoTRegisterByMail.h"
#import "IoTScanResult.h"

@interface IoTRegisterByPhone ()
{
    NSTimer *counterTimer;
    NSArray *tempDeviceList;
}

@property (weak, nonatomic) IBOutlet UITextField *textPhone;
@property (weak, nonatomic) IBOutlet UITextField *textVC;
@property (weak, nonatomic) IBOutlet IoTPasswordField *textPass;

//获取验证码按钮、确认按钮，等待重复获取验证码
@property (weak, nonatomic) IBOutlet UIButton *btnQVC;
@property (weak, nonatomic) IBOutlet UIButton *btnOK;
@property (weak, nonatomic) IBOutlet UIButton *btnWVC;

@property (nonatomic, assign) BOOL canQueryVerifyCode;
@property (nonatomic, assign) int counter;

@end

@implementation IoTRegisterByPhone

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.textPhone becomeFirstResponder];
    
    self.canQueryVerifyCode = NO;
    [self updateViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [XPGWifiSDK sharedInstance].delegate = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //清除密码
    self.textPass.text = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)updateViews
{
    self.textPhone.enabled = !self.canQueryVerifyCode;
    self.btnQVC.alpha = !self.canQueryVerifyCode;
    self.btnWVC.alpha = self.canQueryVerifyCode;
    self.btnOK.alpha = self.canQueryVerifyCode;
    self.textVC.alpha = self.canQueryVerifyCode;
    self.textPass.alpha = self.canQueryVerifyCode;
}

#pragma mark 60 seconds countdown for verify code
- (void)startCountDown
{
    self.counter = 60;
    [counterTimer invalidate];
    counterTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDownTimer) userInfo:nil repeats:YES];
    [self countDownTimer];
}
                    
- (void)countDownTimer
{
    NSString *title = @"重新获取";
    if(self.counter > 0)
    {
        title = [NSString stringWithFormat:@"%i秒后重新获取", self.counter];
        [self.btnWVC setTitle:title forState:UIControlStateDisabled];
    }
    else
    {
        [self.btnWVC setTitle:title forState:UIControlStateNormal];
    }
    self.btnWVC.enabled = self.counter == 0;
    
    //清理计时器
    if(self.counter == 0)
    {
        [counterTimer invalidate];
        return;
    }
    self.counter--;
}

- (void)setCanQueryVerifyCode:(BOOL)canQueryVerifyCode
{
    BOOL isModified = (_canQueryVerifyCode != canQueryVerifyCode);
    _canQueryVerifyCode = canQueryVerifyCode;
    if(_canQueryVerifyCode)
        [self startCountDown];
    
    if(isModified)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationsEnabled:YES];
        [self updateViews];
        [UIView commitAnimations];
    }
}

- (BOOL)validatePhone
{
    BOOL ret = [ProcessModel validatePhone:self.textPhone.text];
    if(!ret)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"手机号不正确，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    return ret;
}

#pragma mark - Action
- (BOOL)IoTStepFrameShouldCancelStep {
    if(self.canQueryVerifyCode)
    {
        self.canQueryVerifyCode = NO;
        return YES;
    }
    return NO;
}

- (IBAction)onQueryVerifyCode:(id)sender {
    [self.textPhone resignFirstResponder];
    
    if(![self validatePhone])
        return;
    
    ProcessModel.hud.labelText = @"正在请求验证码，请稍候...";
    [ProcessModel.hud show:YES];
    [[XPGWifiSDK sharedInstance] requestSendVerifyCode:self.textPhone.text];
}

- (IBAction)onRegisterByMail:(id)sender {
    IoTRegisterByMail *registerByMail = [[IoTRegisterByMail alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    [self.navigationController pushViewController:registerByMail animated:YES];
}

- (IBAction)onConfirm:(id)sender {
    if(self.textVC.text.length == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入验证码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
        
    if(self.textPass.text.length == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"密码不能为空，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
    
    if(self.textPass.text.length < 6 || self.textPass.text.length > 16)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"密码长度要求介于 6-16 之间" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
    
    if(![ProcessModel validatePassword:self.textPass.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"密码只能是数字、大小写或特殊字符" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
    
    [self.textPhone resignFirstResponder];
    [self.textPass resignFirstResponder];
    [self.textVC resignFirstResponder];
    
    if(![self validatePhone])
        return;
    
    ProcessModel.hud.labelText = @"注册中...";
    [ProcessModel.hud show:YES];
    [[XPGWifiSDK sharedInstance] registerUserByPhoneAndCode:self.textPhone.text password:self.textPass.text code:self.textVC.text];
}

- (void)onAddDevice
{
    //添加未绑定的设备到列表
    NSMutableArray *devices = [NSMutableArray array];
    for(XPGWifiDevice *device in tempDeviceList)
    {
        if(device.isLAN && ![device isBind:ProcessModel.uid])
            [devices addObject:device];
    }
    
    [ProcessModel.hud hide:YES];
    IoTScanResult *scanResult = [[IoTScanResult alloc] initWithDevices:[NSArray arrayWithArray:devices]];
    [self.navigationController pushViewController:scanResult animated:YES];
}

#pragma mark XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRequestSendVerifyCode:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    if([error intValue] != 0)
    {
        //8:{"code":9,"msg":"同一手机号5分钟内重复提交相同的内容超过3次","detail":"同一个手机号 xxxxxxxxxxx 5分钟内重复提交相同的内容超过3次"}
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"获取短信失败。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    else
    {
        self.canQueryVerifyCode = YES;
    }
    
    [ProcessModel.hud hide:YES];
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRegisterUser:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    int errorValue = [error intValue];
    if(errorValue)
    {
        NSString *message = errorMessage;
        switch (errorValue) {
            case 9010:
                message = @"验证码不正确";
                break;
            case 9018:
                message = @"用户已注册，请勿重复注册";
                break;
            default:
                break;
        }
        [[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    else
    {
        //保存相关信息
        ProcessModel.uid = uid;
        ProcessModel.token = token;
        ProcessModel.username = self.textPhone.text;
        ProcessModel.password = self.textPass.text;
        ProcessModel.accountType = IoTAccountTypeDefault;
        
        //注册成功后，搜索设备，5秒后进 Step2
        ProcessModel.hud.labelText = @"搜索设备中...";
        
        [[XPGWifiSDK sharedInstance] getBoundDevicesWithUid:ProcessModel.uid token:ProcessModel.token specialProductKeys:ProcessModel.product, nil];
        [self performSelector:@selector(onAddDevice) withObject:nil afterDelay:5];
        return;
    }
    [ProcessModel.hud hide:YES];
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didDiscovered:(NSArray *)deviceList result:(int)result
{
    tempDeviceList = deviceList;
}

@end
