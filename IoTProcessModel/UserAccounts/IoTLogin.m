/**
 * IoTLogin.m
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

#import "IoTLogin.h"
#import "IoTStepFrame.h"
#import "IoTRegisterByPhone.h"
#import "IoTForgetPassword.h"

#define ALERT_TAG_USERNAME          1
#define ALERT_TAG_PASSWORD          2

@interface IoTLogin ()

@property (weak, nonatomic) IBOutlet UITextField *textUser;
@property (weak, nonatomic) IBOutlet UITextField *textPass;

@end

@implementation IoTLogin

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //只需要执行一次
    if(ProcessModel.isRegisteredUser)
    {
        ProcessModel.hud.labelText = @"自动登录中...";
        [ProcessModel.hud show:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(nil == self.navigationController)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"这个视图必须是使用 UINavigationController 加载。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        abort();
    }
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [XPGWifiSDK sharedInstance].delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [XPGWifiSDK sharedInstance].delegate = nil;
    
    [self.textUser resignFirstResponder];
    [self.textPass resignFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //清除密码
    self.textPass.text = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Action
- (void)didBecomeActive {
    [self.textUser resignFirstResponder];
    [self.textPass resignFirstResponder];
}

- (IBAction)onTap:(id)sender {
    // 关闭键盘
    if([sender isMemberOfClass:[UITapGestureRecognizer class]])
    {
        [self.textUser resignFirstResponder];
        [self.textPass resignFirstResponder];
    }

    if(self.textUser.isFirstResponder || self.textPass.isFirstResponder)
        return;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:YES];
    CGRect rc = self.view.frame;
    rc.origin.y = 0;
    self.view.frame = rc;
    [UIView commitAnimations];
}

- (IBAction)onLogin:(id)sender {
    if(self.textUser.text.length == 0)
    {
        UIAlertView *_alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"手机或邮箱不能为空" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        _alertView.tag = ALERT_TAG_USERNAME;
        [_alertView show];
        return;
    }
    
    if(self.textPass.text.length == 0)
    {
        UIAlertView *_alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"密码不能为空" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        _alertView.tag = ALERT_TAG_PASSWORD;
        [_alertView show];
        return;
    }
    
    if(![[IoTProcessModel sharedModel] validateEmail:self.textUser.text] &&
       ![[IoTProcessModel sharedModel] validatePhone:self.textUser.text])
    {
        UIAlertView *_alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"用户名格式不正确，请重新输入" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        _alertView.tag = ALERT_TAG_PASSWORD;
        [_alertView show];
        return;
    }
    
    MBProgressHUD *hud = ProcessModel.hud;
    hud.labelText = @"登录中...";
    [hud show:YES];
    
    [[XPGWifiSDK sharedInstance] userLoginWithUserName:self.textUser.text password:self.textPass.text];
}

- (IBAction)onForgetPassword:(id)sender {
    IoTForgetPassword *forgetPassword = [[IoTForgetPassword alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    [self.navigationController pushViewController:forgetPassword animated:YES];
}

- (IBAction)onRegister:(id)sender {
    IoTRegisterByPhone *registerAccount = [[IoTRegisterByPhone alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    IoTStepFrame *stepFrame = [[IoTStepFrame alloc] initWithRootViewController:registerAccount];
    stepFrame.steps = [IoTProcessModel generalSteps];
    [self.navigationController pushViewController:stepFrame animated:YES];
}

#pragma mark - TextField Delegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGFloat y = 0;
    if(textField == self.textUser || textField == self.textPass)
        y = isPhone4s ? -55 : -50;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:YES];
    CGRect rc = self.view.frame;
    rc.origin.y = y;
    self.view.frame = rc;
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self performSelector:@selector(onTap:) withObject:nil afterDelay:0.2];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.textUser)
        [self.textPass becomeFirstResponder];
    
    if(textField == self.textPass)
    {
        [textField resignFirstResponder];
        [self onLogin:textField];
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case ALERT_TAG_USERNAME:
            [self.textUser becomeFirstResponder];
            break;
        case ALERT_TAG_PASSWORD:
            [self.textPass becomeFirstResponder];
            break;
        default:
            break;
    }
}

#pragma mark XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    if([error intValue])
    {
        [ProcessModel.hud hide:YES];
        
        NSString *message = [NSString stringWithFormat:@"登录失败：%@", errorMessage];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        ProcessModel.accountType = IoTAccountTypeDefault;
        ProcessModel.uid = uid;
        ProcessModel.token = token;
        
        if(self.textUser.text.length > 0 && self.textPass.text.length > 0)
        {
            ProcessModel.username = self.textUser.text;
            ProcessModel.password = self.textPass.text;
        }
        
        [ProcessModel.hud hide:YES];
    }
    
    if([ProcessModel.delegate respondsToSelector:@selector(IoTProcessModelDidLogin:)])
        [ProcessModel.delegate IoTProcessModelDidLogin:error.integerValue];
}

@end
