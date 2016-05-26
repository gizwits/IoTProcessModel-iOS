/**
 * IoTRegisterByMail.m
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

#import "IoTRegisterByMail.h"
#import "IoTScanResult.h"

@interface IoTRegisterByMail ()
{
    NSArray *tempDeviceList;
}

@property (weak, nonatomic) IBOutlet UITextField *textMail;
@property (weak, nonatomic) IBOutlet IoTPasswordField *textPass;

@end

@implementation IoTRegisterByMail

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.textMail becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)validateMail
{
    BOOL ret = [ProcessModel validateEmail:self.textMail.text];
    if(!ret)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"邮箱格式不正确，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    return ret;
}

#pragma mark - action
- (IBAction)onConfirm:(id)sender {
    if(self.textMail.text.length == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"邮箱不能为空" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
    
    if(![ProcessModel validateEmail:self.textMail.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"邮箱格式不正确，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
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
    
    [self.textMail resignFirstResponder];
    [self.textPass resignFirstResponder];
    
    ProcessModel.hud.labelText = @"正在注册...";
    [ProcessModel.hud show:YES];
    [[XPGWifiSDK sharedInstance] registerUserByEmail:self.textMail.text password:self.textPass.text];
}

- (IBAction)onRegisterPhone:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRegisterUser:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    int errorValue = [error intValue];
    if(errorValue)
    {
        NSString *message = errorMessage;
        switch (errorValue) {
            case 9022:
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
        ProcessModel.username = self.textMail.text;
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
