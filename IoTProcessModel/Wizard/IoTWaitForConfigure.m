/**
 * IoTWaitForConfigure.m
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

#import "IoTWaitForConfigure.h"
#import "IoTConfigureFailed.h"
#import "IoTDeviceList.h"
#import "IoTBindFailed.h"
#import "IoTConfigureResult.h"

@interface IoTWaitForConfigure () <XPGWifiSDKDelegate>
{
    NSTimer *waitTimer;
    
    //用于返回页面时重置
    NSInteger resetTimeout;
}

@property (assign, nonatomic) NSInteger timeout;
@property (assign, nonatomic) IoTWaitForConfigureType type;

@property (weak, nonatomic) IBOutlet UILabel *textTime;

@end

@implementation IoTWaitForConfigure

- (id)initWithTimeout:(NSInteger)timeout andType:(IoTWaitForConfigureType)type
{
    self = [super initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    if(self)
    {
         resetTimeout = timeout;
        self.type = type;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.textTime.text = [NSString stringWithFormat:@"%@", @(resetTimeout)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
    
    self.timeout = resetTimeout;
    [waitTimer invalidate];
    waitTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [XPGWifiSDK sharedInstance].delegate = nil;
    [waitTimer invalidate];
    waitTimer = nil;
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

- (void)onTimer
{
    if(self.timeout == 0)
    {
        [waitTimer invalidate];
        waitTimer = nil;
        
        [self configureFailed];
        return;
    }
    self.timeout --;
    self.textTime.text = [NSString stringWithFormat:@"%@", @(self.timeout)];
}

#pragma mark - XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didSetDeviceWifi:(XPGWifiDevice *)device result:(int)result
{
    // XPGWifiError_CONFIGURE_TIMEOUT：配置超时
    if(result == 0)
    {
        //配置成功
        [self configureSucceed];
    }
    else
    {
        [self configureFailed];
    }
}

- (void)configureSucceed
{
    if(self.navigationController.viewControllers.lastObject != self)
    {
        NSLog(@"%s: warning: navigation current state is error, skip.", __func__);
        return;
    }
        
    switch (self.type) {
        case IoTWaitForConfigureTypeAirLink:
        {
            UIViewController *deviceListCtrl = nil;
            for(UIViewController *ctrl in self.stepFrame.navigationController.viewControllers)
            {
                if([ctrl isKindOfClass:[IoTDeviceList class]])
                    deviceListCtrl = ctrl;
            }
            
            if(nil == deviceListCtrl)
                deviceListCtrl = ProcessModel.deviceListController;
            
            [self.stepFrame cancelTo:deviceListCtrl animated:YES];
            break;
        }
        default:
        {
            IoTConfigureResult *configureResult = [[IoTConfigureResult alloc] initWithResult:XPGWifiError_NONE];
            [self.navigationController pushViewController:configureResult animated:YES];
            break;
        }
    }
}

- (void)configureFailed
{
    if(self.navigationController.viewControllers.lastObject != self)
    {
        NSLog(@"%s: warning: navigation current state is error, skip.", __func__);
        return;
    }

    switch (self.type) {
        case IoTWaitForConfigureTypeAirLink:
        {
            //AirLink模式配置失败
            IoTConfigureFailed *confFail = [[IoTConfigureFailed alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
            [self.navigationController pushViewController:confFail animated:YES];
            break;
        }
        default:
        {
            //SoftAP模式配置失败
            IoTConfigureResult *configureResult = [[IoTConfigureResult alloc] initWithResult:XPGWifiError_GENERAL];
            [self.navigationController pushViewController:configureResult animated:YES];
            break;
        }
    }
}

- (BOOL)IoTStepFrameShouldCancelStep {
    if(self.navigationController.viewControllers.lastObject != self)
    {
        NSLog(@"%s: warning: navigation current state is error, skip.", __func__);
        return NO;
    }
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

@end
