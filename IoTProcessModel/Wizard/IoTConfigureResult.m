/**
 * IoTConfigureResult.m
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

#import "IoTConfigureResult.h"
#import "IoTScanResult.h"
#import "IoTSetWifi.h"

@interface IoTConfigureResult ()

@property (nonatomic, assign) int result;

@property (weak, nonatomic) IBOutlet UILabel *textMessage;

@property (weak, nonatomic) IBOutlet UIButton *btnSuccess;
@property (weak, nonatomic) IBOutlet UIButton *btnRetry;

@property (weak, nonatomic) IBOutlet UIImageView *imgIcon;

@end

@implementation IoTConfigureResult

- (id)initWithResult:(int)result
{
    self = [super initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    if(self)
    {
        self.result = result;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if(self.result == XPGWifiError_NONE)
    {
        self.textMessage.text = @"配置成功，记得切换回Wi-Fi网络哦！";
        [self.btnRetry removeFromSuperview];
        
        self.imgIcon.image = [IoTProcessModel imageWithFileName:@"success"];
    }
    else
    {
        self.textMessage.text = @"配置失败了，请拔下设备电源，再重新接通电源，再点击重试。";
        [self.btnSuccess removeFromSuperview];
    }
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

- (IBAction)onOK:(id)sender {
    //返回列表
    UIViewController *deviceListCtrl = nil;
    for(UIViewController *ctrl in self.stepFrame.navigationController.viewControllers)
    {
        if([ctrl isKindOfClass:[IoTDeviceList class]])
            deviceListCtrl = ctrl;
    }
    
    if(nil == deviceListCtrl)
        deviceListCtrl = ProcessModel.deviceListController;
    
    [self.stepFrame cancelTo:deviceListCtrl animated:YES];
    
    //在这里，要删掉上一个Step
    IoTSetWifi *setWifi = (IoTSetWifi *)self.navigationController.viewControllers.firstObject;
    IoTStepFrame *stepFrame = setWifi.lastStep;
    [ProcessModel performSelector:@selector(removeStepFrame:) withObject:stepFrame afterDelay:0.5];
}

- (IBAction)onRetry:(id)sender {
    [self.stepFrame cancel:YES];
}

@end
