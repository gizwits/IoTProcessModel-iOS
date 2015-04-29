/**
 * IoTForgetPassword.m
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

#import "IoTForgetPassword.h"

@interface IoTForgetPassword () <UIAlertViewDelegate>
{
    NSTimer *counterTimer;
    BOOL isMail;
}

@property (weak, nonatomic) IBOutlet UITextField *textUser;
@property (weak, nonatomic) IBOutlet UITextField *textVC;
@property (weak, nonatomic) IBOutlet UITextField *textPass;

//获取验证码按钮、确认按钮，等待重复获取验证码
@property (weak, nonatomic) IBOutlet UIButton *btnQVC;
@property (weak, nonatomic) IBOutlet UIButton *btnWVC;
@property (weak, nonatomic) IBOutlet UIButton *btnOK;

@property (nonatomic, assign) BOOL canQueryVerifyCode;
@property (nonatomic, assign) int counter;

@end

@implementation IoTForgetPassword

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.textUser becomeFirstResponder];
    
    self.canQueryVerifyCode = NO;
    [self updateViews];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[IoTProcessModel imageWithFileName:@"return_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
    self.navigationItem.title = @"忘记密码";
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [XPGWifiSDK sharedInstance].delegate = nil;
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
    self.textUser.enabled = !self.canQueryVerifyCode;
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

#pragma mark - Action
- (IBAction)onQueryVerifyCode:(id)sender {
    if([ProcessModel validatePhone:self.textUser.text])
    {
        isMail = NO;
        ProcessModel.hud.labelText = @"正在请求验证码，请稍候...";
        [ProcessModel.hud show:YES];
        [[XPGWifiSDK sharedInstance] requestSendVerifyCode:self.textUser.text];
    }
    else if([ProcessModel validateEmail:self.textUser.text])
    {
        isMail = YES;
        ProcessModel.hud.labelText = @"请稍候...";
        [ProcessModel.hud show:YES];
        [[XPGWifiSDK sharedInstance] changeUserPasswordByEmail:self.textUser.text];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"用户名不正确，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
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
    
    if([ProcessModel validatePhone:self.textUser.text])
    {
        ProcessModel.hud.labelText = @"重置中...";
        [ProcessModel.hud show:YES];
        [[XPGWifiSDK sharedInstance] changeUserPasswordByCode:self.textUser.text code:self.textVC.text newPassword:self.textPass.text];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"手机号不正确，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
}

- (void)onBack
{
    if(self.canQueryVerifyCode)
    {
        self.canQueryVerifyCode = NO;
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRequestSendVerifyCode:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    if([error intValue] != 0)
    {
        //8:{"code":9,"msg":"同一手机号5分钟内重复提交相同的内容超过3次","detail":"同一个手机号 xxxxxxxxxxx 5分钟内重复提交相同的内容超过3次"}
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"获取验证码失败。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    else
    {
        self.canQueryVerifyCode = YES;
    }
    
    [ProcessModel.hud hide:YES];
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserPassword:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    int errorValue = [error intValue];
    if(errorValue)
    {
        NSString *message = errorMessage;
        switch (errorValue) {
            case 9010:
                message = @"验证码不正确";
                break;
            default:
                break;
        }
        [[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    else
    {
        //忘记密码重置成功后，按确定登录界面
        NSString *message = @"重置成功";
        if(isMail)
        {
            message = @"已向指定邮箱发送重置邮件，请通过指定的邮件重设密码";
        }
        
        [[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    
    [ProcessModel.hud hide:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
