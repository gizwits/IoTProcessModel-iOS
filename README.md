IoTProcessModel，是公共开源项目基本流程的整合库。整合了登陆、注册、绑定、添加设备的流程，以及设备列表的整合。

使用方法：

##一、初始化

	[IoTProcessModel startWithAppID:...]

##二、单例

	[IoTProcessModel sharedModel]

##三、公开的界面

* 登录页面

	[IoTProcessModel sharedModel].loginController

* 设备列表

	[IoTProcessModel sharedModel].deviceListController


具体流程说明：

###1、登录、注册流程

<pre>
         登录
          |
 -------------------—-
 |        |          |
登录      注册      忘记密码
 |
回调
</pre>

登录方式：手机（优先）/邮箱（邮箱暂未支持）


<pre>
                   注册
                    |
              通过手机/邮箱注册
                    |
         ----------------——————
         |                    |
  Air Link 添加设备        二维码扫描
         |                    |
 -------------—————     ————————————
 |                |     |          |
成功              失败  返回        成功
 |                |                |
回调         ——————————————        回调
            |             |
         重新配置     配置 Soft AP
                          |
                   ————————————————
                   |              |
                  成功            失败
                   |              |
                  回调          重新配置
</pre>

这里就有4个回调的地方：

* 执行登录操作的回调
* Air Link 配置成功
* 二维码扫描并绑定成功
* Soft AP 配置成功

###2、设备列表

<pre>
            设备列表
               |
   ---------------————-------
   |        |       |       |
添加设备    注销     绑定     控制
            |               |
           回调             回调
</pre>

这里有2个回调的地方

* 注销
* 控制

##文件夹功能

Wizard：注册向导<br>
Devices：设备相关<br>
UserAccounts：用户登录相关<br>
Utils：依赖的第三方库

##文件功能说明

IoTProcessModel 核心类：

1. 提供快速初始化的页面接口
2. 保存用户信息
3. 控制回调信息

##用户登录、注册部分
IoTLogin 登录
IoTForgetPasswordByPhone 使用手机找回密码
IoTForgetPasswordByMail 使用邮箱找回密码

IoTRegisterByPhone 使用手机注册
IoTRegisterByMail 使用邮箱注册
IoTScanResult 搜索设备结果

#以下是向导部分
IoTStepFrame 向导框架

##1、配置设备上网部分 Airlink
IoTAddDevice 通过 AirLink 方式添加设备
IoTConfigure 支持两种模式：

1. 获取 passcode 并绑定
2. 配置 AirLink 方式

IoTWaitForConfigure 等待配置：支持3种方式：

1. Soft AP
2. Air Link
3. 绑定

IoTConfigureFailed AirLink 模式配置失败

##2、配置设备上网部分 Soft AP
IoTSetWifi 检测 Wifi 状态然后自动跳转
IoTSoftAPConfigure 配置 Wifi 密码
IoTConfigureResult Soft AP 模式配置结果

##3、配置设备绑定部分
IoTBindFailed 绑定失败页面/绑定帮助

图片为 airconditioner-iOS 的配图，如有需要更改，请自行更换。

