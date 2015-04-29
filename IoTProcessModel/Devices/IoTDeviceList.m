/**
 * IoTDeviceList.m
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

#import "IoTDeviceList.h"
#import <AFNetworking/AFNetworking.h>
#import <XPGWifiSDK/XPGWifiSDK.h>

#import "IoTLogin.h"
#import "IoTScanResult.h"
#import "IoTStepFrame.h"

#import "SSPullToRefresh.h"

#define QR_SIMULATOR 0

/*
 wifi模式
 查找设备，如果找到设备，则是小循环，否则是大循环
 
 3G模式
 均为大循环
 */
@interface IoTDeviceList () <SSPullToRefreshViewDelegate>
{
    /*是否登录*/
    BOOL isDiscoverLock;
   
    XPGWifiDevice *selectedDevices;
    UIAlertView *_alertView;
    NSArray *headers;
}

@property (strong, nonatomic) NSArray *arrayList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign) BOOL isToasted;

@property (strong, nonatomic) SSPullToRefreshView *pullToRefreshView;

@end

@implementation IoTDeviceList

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    headers = @[@"已绑定的设备", @"发现新设备", @"离线设备"];
   
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:[IoTProcessModel imageWithFileName:@"logout_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onLogout)];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddItem)];
    
    self.navigationItem.leftBarButtonItem = leftItem;
    self.navigationItem.rightBarButtonItem = rightItem;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"设备列表";
    
#if QR_SIMULATOR
    [self performSelector:@selector(qrcodeSimulator) withObject:nil afterDelay:1];
#endif
    
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
}

#if QR_SIMULATOR
- (void)qrcodeSimulator
{
    NSString *did = @"MMAKaGLdv3A8cQ9N9TGDzM";
    NSString *passcode = @"123456";
    ProcessModel.hud.labelText = [NSString stringWithFormat:@"正在绑定%@...", selectedDevices.macAddress];
    [ProcessModel.hud show:YES];
    [[XPGWifiSDK sharedInstance] bindDeviceWithUid:ProcessModel.uid token:ProcessModel.token did:did passCode:passcode remark:nil];
}
#endif

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(nil == self.navigationController)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"这个视图必须是使用 UINavigationController 加载。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        abort();
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if(nil != selectedDevices)
        [selectedDevices disconnect];
    
    [[AFNetworkReachabilityManager sharedManager] addObserver:self forKeyPath:@"networkReachabilityStatus" options:NSKeyValueObservingOptionNew context:nil];
    [self checkNetwokStatus];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReload) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [XPGWifiSDK sharedInstance].delegate = self;
    
    /*
     进入列表的时候下载一次
     */
    [self onReload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if([[UIDevice currentDevice].systemVersion floatValue] < 7.0)
        [self unLockList];
    
    [[AFNetworkReachabilityManager sharedManager] removeObserver:self forKeyPath:@"networkReachabilityStatus"];
    
    [XPGWifiSDK sharedInstance].delegate = nil;
    selectedDevices.delegate = nil;

    [self LockList];
    for(NSArray *section in self.arrayList)
        for(XPGWifiDevice *device in section)
            device.delegate = nil;
    [self unLockList];
    
    NSArray *oldList = self.arrayList;
    self.arrayList = nil;
    ProcessModel.devicesList = oldList;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 列表部分
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return headers[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    [self LockList];
    NSArray *arrSection = self.arrayList[section];
    NSInteger count = arrSection.count;
    if(count == 0)
        count = 1;
    [self unLockList];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strIdentifier = @"IotDeviceIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:strIdentifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:strIdentifier];
    
    /*
     重用，需要重新设置属性
     */
    cell.textLabel.text = @"";
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.numberOfLines = 1;
    
    [self LockList];
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:0xfff0];
    if(nil == label)
    {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.tag = 0xfff0;
        label.textAlignment = NSTextAlignmentRight;
        
        cell.accessoryView = label;
    }
    
    // Accessory image
    UIImageView *imgView = (UIImageView *)[label viewWithTag:0xfff1];
    [imgView removeFromSuperview];
    CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    
    label.textColor = [UIColor blackColor];
    label.frame = CGRectMake(280, 0, 60, height);

    NSArray *arrSection = self.arrayList[indexPath.section];
    if(indexPath.row + 1 > arrSection.count)
    {
        if([ProcessModel.delegate respondsToSelector:@selector(IoTProcessModelGetDeviceImage:section:)])
            cell.imageView.image = [ProcessModel.delegate IoTProcessModelGetDeviceImage:nil section:indexPath.section];
        else
            cell.imageView.image = [IoTProcessModel imageWithFileName:@"device-37"];
        
        cell.textLabel.text = @"没有设备";
        label.text = @"";
    }
    else
    {
        XPGWifiDevice *device = arrSection[indexPath.row];
        
        //自定义文字
        if([ProcessModel.delegate respondsToSelector:@selector(IoTProcessModelGetDeviceCustomText:)])
        {
            cell.textLabel.text = [ProcessModel.delegate IoTProcessModelGetDeviceCustomText:device];
        }
        else
        {
            if(device.remark.length == 0)
                cell.textLabel.text = device.productName;
            else
                cell.textLabel.text = device.remark;
        }
        
        //自定义图片
        if([ProcessModel.delegate respondsToSelector:@selector(IoTProcessModelGetDeviceImage:section:)])
        {
            cell.imageView.image = [ProcessModel.delegate IoTProcessModelGetDeviceImage:device section:indexPath.section];
        }
        else
        {
            switch (indexPath.section) {
                case 0:
                case 1:
                    //在线
                    cell.imageView.image = [IoTProcessModel imageWithFileName:@"device-29"];
                    break;
                case 2:
                    //离线
                    cell.imageView.image = [IoTProcessModel imageWithFileName:@"device-37"];
                    break;
                    
                default:
                    break;
            }
        }
        
        cell.detailTextLabel.text = device.macAddress;
        if(device.isLAN)
        {
            if(![device isBind:ProcessModel.uid])
            {
                label.text = @"未绑定";
                
                imgView = [[UIImageView alloc] initWithImage:[IoTProcessModel imageWithFileName:@"device_list-34"]];
                imgView.tag = 0xfff1;
                imgView.frame = CGRectMake(62, 38, 8, 15);
                [label addSubview:imgView];
            }
            else
            {
                label.text = @"局域网已连接";
                
                imgView = [[UIImageView alloc] initWithImage:[IoTProcessModel imageWithFileName:@"device_list-31"]];
                imgView.tag = 0xfff1;
                imgView.frame = CGRectMake(107, 38, 8, 15);
                [label addSubview:imgView];
                label.frame = CGRectMake(200, 0, 105, height);
            }
        }
        else
        {
            if(!device.isOnline)
            {
                cell.textLabel.textColor = [UIColor grayColor];
                cell.detailTextLabel.textColor = [UIColor grayColor];
                label.textColor = [UIColor grayColor];
                label.text = @"离线";
            }
            else
            {
                label.text = @"远程已连接";
                label.frame = CGRectMake(200, 0, 90, height);
                
                imgView = [[UIImageView alloc] initWithImage:[IoTProcessModel imageWithFileName:@"device_list-31"]];
                imgView.tag = 0xfff1;
                imgView.frame = CGRectMake(92, 38, 8, 15);
                [label addSubview:imgView];
            }
        }
    }
    
    [self unLockList];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(isDiscoverLock)
        return;
    
    //离线设备无法进入主页面
    if(indexPath.section == 2)
        return;
    
    [self LockList];
    
    //连接后不用解锁，等到收到连接事件后解锁
    NSArray *arrSection = self.arrayList[indexPath.section];
    selectedDevices = arrSection[indexPath.row];
    selectedDevices.delegate = self;

    if ([selectedDevices isBind:ProcessModel.uid] &&
        [selectedDevices.passcode length]) {
        //未连接，则执行登录
        if(!selectedDevices.isConnected)
        {
            ProcessModel.hud.labelText = [NSString stringWithFormat:@"正在登录%@...", selectedDevices.macAddress];
            [ProcessModel.hud show:YES];
            
            [selectedDevices login:ProcessModel.uid token:ProcessModel.token];
        }
        else
            [self pushToControlPage];
    } else {
        if(selectedDevices.did.length == 0)
        {
            [[[UIAlertView alloc] initWithTitle:@"提示" message:@"此设备尚未与云端注册，无法绑定。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        }
        else
        {
            ProcessModel.hud.labelText = [NSString stringWithFormat:@"正在绑定%@...", selectedDevices.macAddress];
            [ProcessModel.hud show:YES];
            [[XPGWifiSDK sharedInstance] bindDeviceWithUid:ProcessModel.uid token:ProcessModel.token did:selectedDevices.did passCode:nil remark:nil];
        }
    }

    [self unLockList];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arrSection = self.arrayList[indexPath.section];
    if(arrSection.count == 0)
        return NO;
    return YES;
}

#pragma mark - Action
- (void)pushToControlPage
{
    @try {
        if(self.navigationController.viewControllers.lastObject == self)
        {
            // 将结果回调出去
            if([ProcessModel.delegate respondsToSelector:@selector(IoTProcessModelDidControlDevice:)])
                [ProcessModel.delegate IoTProcessModelDidControlDevice:selectedDevices];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"error:%@", exception);
    }
}

- (void)onLogout
{
    [[[UIAlertView alloc] initWithTitle:@"提示" message:@"是否确定注销？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil] show];
}

- (void)onReload
{
    //防止操作中点了以后卡主线程或者Delegate没设置的时候不执行。
    if(isDiscoverLock || nil == [XPGWifiSDK sharedInstance].delegate)
        return;
    
    //开始加载
    [self.pullToRefreshView startLoading];
    self.tableView.userInteractionEnabled = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [[XPGWifiSDK sharedInstance] getBoundDevicesWithUid:ProcessModel.uid token:ProcessModel.token specialProductKeys:ProcessModel.product, nil];
}

- (void)onAddItem
{
    NSArray *devices = nil;
    if(self.arrayList.count > 0)
        devices = self.arrayList[1];

    IoTScanResult *scanResult = [[IoTScanResult alloc] initWithDevices:devices];
    IoTStepFrame *stepFrame = [[IoTStepFrame alloc] initWithRootViewController:scanResult];
        
    stepFrame.steps = [IoTProcessModel generalSteps];
    stepFrame.currentStepIndex = 1;
    
    [self.navigationController pushViewController:stepFrame animated:YES];
}

#pragma mark - Property
- (void)setArrayList:(NSArray *)arrayList
{
    [self LockList];
    
    //分类
    NSMutableArray
    *arr1 = [NSMutableArray array], //在线
    *arr2 = [NSMutableArray array], //新设备
    *arr3 = [NSMutableArray array]; //不在线
    
    for(XPGWifiDevice *device in arrayList)
    {
        //已被标记为禁用的设备，过滤
        if (device.isDisabled)
            continue;

        if(device.isLAN && ![device isBind:ProcessModel.uid])
        {
            [arr2 addObject:device];
            continue;
        }
        if(device.isLAN || device.isOnline)
        {
            [arr1 addObject:device];
            continue;
        }
        [arr3 addObject:device];
    }
    
    _arrayList = @[arr1, arr2, arr3];
    [self unLockList];
    [self.tableView reloadData];
    
    //保存列表到接口
    ProcessModel.devicesList = _arrayList;
}

#pragma mark - 列表回调
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didDiscovered:(NSArray *)deviceList result:(int)result
{
    if(isDiscoverLock)
        return;
    
    for(XPGWifiDevice *device in deviceList)
        device.delegate = self;
    
    self.arrayList = deviceList;
    
    //完成加载
    [self.pullToRefreshView finishLoading];
    self.tableView.userInteractionEnabled = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if([selectedDevices.macAddress isEqualToString:device.macAddress] &&
       [selectedDevices.did isEqualToString:device.did])
    {
        if(ProcessModel.hud.alpha == 1 && [ProcessModel.hud.labelText isEqualToString:@"登录中..."])
        {
            [_alertView dismissWithClickedButtonIndex:0 animated:NO];
            _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"登录失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [_alertView show];
        }
        else if (ProcessModel.hud.alpha == 1 && [ProcessModel.hud.labelText isEqualToString:@"连接中..."])
        {
            [_alertView dismissWithClickedButtonIndex:0 animated:NO];
            _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"连接失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [_alertView show];
        }
        
        [ProcessModel.hud hide:YES];
//       NSLog(@"Disconnected device:%@, %@, %@, %@", device.macAddress, device.did, device.passcode, device.productKey);
        selectedDevices.delegate = nil;
        selectedDevices = nil;
    }
}

- (void)XPGWifiDevice:(XPGWifiDevice *)device didLogin:(int)result
{
    if([selectedDevices.macAddress isEqualToString:device.macAddress] &&
       [selectedDevices.did isEqualToString:device.did] &&
       ![ProcessModel.hud.labelText hasPrefix:@"正在绑定"])
    {
        [ProcessModel.hud hide:YES];
        [self unLockList];
        if(result == 0)
        {
            [self pushToControlPage];
        }
        else
        {
            if(selectedDevices)
            {
                if(selectedDevices.isConnected)
                    [selectedDevices disconnect];
            }
            
            [_alertView dismissWithClickedButtonIndex:0 animated:NO];
            _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"登录失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [_alertView show];
        }
    }
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    [ProcessModel.hud hide:YES];
    [_alertView dismissWithClickedButtonIndex:0 animated:YES];
    
    if (![error intValue]) {
        _alertView = [[UIAlertView alloc] initWithTitle:@"绑定成功" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    } else {
        _alertView = [[UIAlertView alloc] initWithTitle:@"绑定失败" message:errorMessage delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    }
    
    [self onReload];
    
    [_alertView show];
}

#pragma mark - 设备列表锁
- (void)LockList
{
    while (isDiscoverLock) {
        usleep(1000);
    }
    isDiscoverLock = YES;
}

- (void)unLockList
{
    isDiscoverLock = NO;
}

#pragma mark - 检查网络
- (void)checkNetwokStatus
{
    //    NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus));
    switch ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus) {
        case AFNetworkReachabilityStatusReachableViaWiFi:
        case AFNetworkReachabilityStatusReachableViaWWAN:
        {
            self.navigationItem.rightBarButtonItem.enabled = YES;
            break;
        }
        case AFNetworkReachabilityStatusNotReachable:
        {
            self.navigationItem.rightBarButtonItem.enabled = NO;
            break;
        }
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"networkReachabilityStatus"])
        [self checkNetwokStatus];
}

#pragma mark - 其他
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex])
    {
        ProcessModel.hud.labelText = @"注销中...";
        [ProcessModel.hud show:YES];
        [ProcessModel logout];
    }
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view
{
    [self onReload];
}

@end