/**
 * IoTScanResult.m
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

#import "IoTScanResult.h"
#import "ZBarSDK.h"
#import "IoTWifiUtil.h"
#import "IoTAddDevice.h"
#import "IoTConfigure.h"
#import "IoTDisconnected.h"

@interface IoTScanResult () <ZBarReaderDelegate>
{
    IoTDisconnected *disconnectCtrl;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UILabel *textNoDev;
@property (weak, nonatomic) IBOutlet UILabel *textNoDev2;

@property (strong, nonatomic) NSArray *devices;

@end

@implementation IoTScanResult

- (id)initWithDevices:(NSArray *)devices
{
    self = [super initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
    if(self)
    {
        self.devices = devices;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if(self.devices.count == 0)
    {
        [self.tableView removeFromSuperview];
    }
    else
    {
        [self.textNoDev removeFromSuperview];
        [self.textNoDev2 removeFromSuperview];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;

    //加个通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResume) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.stepFrame.currentStepIndex = 1;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //防止弹出的时候把delegate赋值
    if(nil == self.stepFrame.presentedViewController)
        [XPGWifiSDK sharedInstance].delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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

- (void)onResume {
    [disconnectCtrl hide:YES];
}

- (IBAction)onScanQRCode:(id)sender {
    if(ProcessModel.subProduct.length > 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"该产品不支持虚拟设备" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
    
    ZBarReaderViewController *reader = [[ZBarReaderViewController alloc] init];
    reader.readerDelegate = self;
    reader.supportedOrientationsMask = ZBarOrientationMaskAll;
    ZBarImageScanner *scanner = reader.scanner;
    [scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to: 0];
    [self.stepFrame presentViewController:reader animated:YES completion:^{
    }];
}

- (IBAction)onConfigure:(id)sender {
    if([IoTWifiUtil isConnectedWifi] && ![IoTWifiUtil isSoftAPMode:XPG_GAGENT])
    {
        IoTAddDevice *addDevice = [[IoTAddDevice alloc] initWithNibName:nil bundle:[IoTProcessModel resourceBundle]];
        [self.navigationController pushViewController:addDevice animated:YES];
    }
    else
    {
        disconnectCtrl = [[IoTDisconnected alloc] init];
        [disconnectCtrl show:YES];
    }
}

- (NSDictionary *)getScanResult:(NSString *)result
{
    NSArray *arr1 = [result componentsSeparatedByString:@"?"];
    if(arr1.count != 2)
        return nil;
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    NSArray *arr2 = [arr1[1] componentsSeparatedByString:@"&"];
    for(NSString *str in arr2)
    {
        NSArray *keyValue = [str componentsSeparatedByString:@"="];
        if(keyValue.count != 2)
            continue;
        
        NSString *key = keyValue[0];
        NSString *value = keyValue[1];
        [mdict setValue:value forKeyPath:key];
    }
    return mdict;
}

- (void)imagePickerController: (UIImagePickerController*)reader didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    // ADD: 获取解码结果
    id<NSFastEnumeration> results =[info objectForKey: ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for(symbol in results) {
        // 例子: 只获取第一个BarCode
        break;
    }
    
    NSString *resultStr=symbol.data;
//处理中文乱码问题
//    if ([resultStr canBeConvertedToEncoding:NSShiftJISStringEncoding]) {
//        resultStr = [NSString stringWithCString:[resultStr cStringUsingEncoding: NSShiftJISStringEncoding]  encoding:NSUTF8StringEncoding];
//    }
    
    NSDictionary *dict = [self getScanResult:resultStr];
    if(nil != dict)
    {
        NSString *did = [dict valueForKey:@"did"];
        NSString *passcode = [dict valueForKey:@"passcode"];
        NSString *productkey = [dict valueForKey:@"product_key"];
        
        //这里，要通过did，passcode，productkey获取一个设备
        if(did.length > 0 && passcode.length > 0 && [productkey isEqualToString:ProcessModel.product])
        {
            ProcessModel.hud.labelText = @"添加中...";
            [ProcessModel.hud show:YES];
            [[XPGWifiSDK sharedInstance] bindDeviceWithUid:ProcessModel.uid token:ProcessModel.token did:did passCode:passcode remark:nil];
            
            [reader dismissViewControllerAnimated:YES completion:^{
            }];
        }
    }
//    // 例子: 处理文本结果
//    resultText.text = resultStr;
//
//    // 例子: 处理barcode图片
//    resultImage.image = [info objectForKey: UIImagePickerControllerOriginalImage];
}

#pragma mark - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"ScanResultIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    XPGWifiDevice *device = self.devices[indexPath.row];
    if(device.remark.length == 0)
        cell.textLabel.text = device.productName;
    else
        cell.textLabel.text = device.remark;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    XPGWifiDevice *device = self.devices[indexPath.row];
    IoTConfigure *configure = [[IoTConfigure alloc] initWithQueryPasscode:device];
    [self.navigationController pushViewController:configure animated:YES];
}

#pragma mark - XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    //退出界面并回调
    [ProcessModel.hud hide:YES];
    
    //跳转页面
    UIViewController *deviceListCtrl = nil;
    for(UIViewController *ctrl in self.stepFrame.navigationController.viewControllers)
    {
        if([ctrl isKindOfClass:[IoTDeviceList class]])
            deviceListCtrl = ctrl;
    }
    
    if(nil == deviceListCtrl)
        deviceListCtrl = ProcessModel.deviceListController;
    
    [self.stepFrame cancelTo:deviceListCtrl animated:YES];
    
    if([ProcessModel.delegate respondsToSelector:@selector(IoTProcessModelDidFinishedAddDevice:)])
        [ProcessModel.delegate IoTProcessModelDidFinishedAddDevice:[error intValue]];
}

@end
