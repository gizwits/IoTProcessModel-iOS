/**
 * IoTConfigure.m
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

#import "IoTConfigure.h"
#import "IoTWaitForConfigure.h"
#import "IoTBindFailed.h"

typedef enum
{
    IoTConfigureTypeBindDevice,
    IoTConfigureTypeAirLink
}IoTConfigureType;

@interface IoTConfigure () <XPGWifiSDKDelegate>

@property (weak, nonatomic) IBOutlet UILabel *textSummary;

@property (weak, nonatomic) IBOutlet UIButton *btnStartConfigure;
@property (weak, nonatomic) IBOutlet UIButton *btnHelp;

@property (assign, nonatomic) IoTConfigureType type;

/**
 * 获取 Passcode 页面专用
 */
@property (strong, nonatomic) XPGWifiDevice *device;


/**
 * 配置 AirLink 页面专用
 */
@property (strong, nonatomic) NSString *ssid;
@property (strong, nonatomic) NSString *password;

@end

@implementation IoTConfigure

- (id)initWithQueryPasscode:(XPGWifiDevice *)device
{
    self = [super initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    if(self)
    {
        self.type = IoTConfigureTypeBindDevice;
        self.device = device;
    }
    return self;
}

- (id)initWithAirLink:(NSString *)ssid password:(NSString *)password
{
    self = [super initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    if(self)
    {
        self.type = IoTConfigureTypeAirLink;
        self.ssid = ssid;
        self.password = password;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 根据类型，去区分对应的配置
    switch (self.type) {
        case IoTConfigureTypeBindDevice:
            self.textSummary.text = @"按下设备按键，灯闪即表示设备已进入配置模式，\n请在此界面等待数秒，界面将自动跳转";
            [self.btnStartConfigure removeFromSuperview];
            break;
        case IoTConfigureTypeAirLink:
            self.textSummary.text = @"请按下设备按键，灯闪即表示设备已进入配置模式，\n点击开始配置";
            [self.btnHelp removeFromSuperview];
            break;
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;

    switch (self.type) {
        case IoTConfigureTypeBindDevice:
            self.stepFrame.currentStepIndex = 2;
            break;
            
        default:
            self.stepFrame.currentStepIndex = 3;
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    switch (self.type) {
        case IoTConfigureTypeBindDevice:
        {
            //执行获取 PASSCODE 并绑定操作
            [[XPGWifiSDK sharedInstance] bindDeviceWithUid:ProcessModel.uid token:ProcessModel.token did:self.device.did passCode:nil remark:nil];
            break;
        }
        case IoTConfigureTypeAirLink:
            //这里不需要执行，等配置才执行
            break;
        default:
            break;
    }
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

- (IBAction)onStartConfigure:(id)sender {
    int timeout = XPG_AIRLINK_TIMEOUT;
    IoTWaitForConfigure *waitForConfigure = [[IoTWaitForConfigure alloc] initWithTimeout:timeout andType:IoTWaitForConfigureTypeAirLink];
    [self.navigationController pushViewController:waitForConfigure animated:YES];
    
    switch (self.type) {
        case IoTConfigureTypeBindDevice:
            //这里不需要执行，在页面中初始化的时候调用过了
            break;
        case IoTConfigureTypeAirLink:
            //执行配置操作
            [[XPGWifiSDK sharedInstance] setDeviceWifi:self.ssid key:self.password mode:XPGWifiSDKAirLinkMode timeout:timeout];
            break;
        default:
            break;
    }
}

- (IBAction)onHelp:(id)sender {
    IoTBindFailed *bindFailed = [[IoTBindFailed alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    [self.navigationController pushViewController:bindFailed animated:YES];
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    if (![error intValue]) {
        //绑定成功
        UIViewController *deviceListCtrl = nil;
        for(UIViewController *ctrl in self.stepFrame.navigationController.viewControllers)
        {
            if([ctrl isKindOfClass:[IoTDeviceList class]])
                deviceListCtrl = ctrl;
        }
        
        if(nil == deviceListCtrl)
            deviceListCtrl = ProcessModel.deviceListController;
        
        [self.stepFrame cancelTo:deviceListCtrl animated:YES];
    } else {
        IoTBindFailed *bindFail = [[IoTBindFailed alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
        [self.navigationController pushViewController:bindFail animated:YES];
    }
    
    //回调
    if(self.type == IoTConfigureTypeBindDevice)
    {
        if([ProcessModel.delegate respondsToSelector:@selector(IoTProcessModelDidFinishedAddDevice:)])
            [ProcessModel.delegate IoTProcessModelDidFinishedAddDevice:[error integerValue]];
    }
}

- (NSString *)IoTStepFrameCustomText:(IoTStepFrame *)sender
{
    if(self.type == IoTConfigureTypeBindDevice)
        return @"   按键";
    return @"配置";
}

- (BOOL)IoTStepFrameShouldCancelStep {
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

@end
