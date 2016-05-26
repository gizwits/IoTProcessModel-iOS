/**
 * IoTConfigureFailed.m
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

#import "IoTConfigureFailed.h"
#import "IoTSetWifi.h"
#import "IoTWifiUtil.h"
#import "IoTScanResult.h"

@interface IoTConfigureFailed ()

@end

@implementation IoTConfigureFailed

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

- (IBAction)onRetry:(id)sender {
    for(UIViewController *controller in self.navigationController.viewControllers)
    {
        if([controller isKindOfClass:[IoTScanResult class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
            break;
        }
    }
}

- (IBAction)onManual:(id)sender {
    if([IoTWifiUtil isSoftAPMode:XPG_GAGENT] || ![IoTWifiUtil isConnectedWifi])
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"请先切换到非 GAgent 的 Wi-Fi 网络。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
    
    IoTSetWifi *setWifi = [[IoTSetWifi alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    setWifi.lastStep = self.stepFrame;
    
    IoTStepFrame *stepFrame = [[IoTStepFrame alloc] initWithRootViewController:setWifi];
    stepFrame.steps = [IoTProcessModel softAPSteps];
    [self.stepFrame nextTo:stepFrame animated:YES];
    [self.stepFrame.navCtrl performSelector:@selector(popToRootViewControllerAnimated:) withObject:@YES afterDelay:0.5];
}

@end
