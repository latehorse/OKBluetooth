!> 为了保证手机端作为 `central`，同时保持多个外设连接和数据接发，蓝牙模块采用单例模式，提供基础功能并暴露部分接口便于接入方调用

## 初始化

仅需初始化 `OKCentralManager`，就会完成整个模块初始化。

``` objectivec
[OKCentralManager sharedInstance];
//设置最大搜索设备数量 默认一直搜索至超时或手动停止
[OKCentralManager sharedInstance].peripheralsCountToStop = 20;
```

## 信号量

提供了几个常用的信号量，如蓝牙状态变化，连接以及断开，可以随时订阅取消。

示例代码

``` objectivec
[[OKCentralManager sharedInstance].scanForPeripheralsCommand.executing subscribeNext:^(NSNumber * _Nullable x) {
    if (x.boolValue) {
        [SVProgressHUD showWithStatus:@"搜索中"];
    } else {
        [SVProgressHUD dismiss];
    }
}];
    
@weakify(self);
[[OKCentralManager sharedInstance].centralManagerStateConnection.signal subscribeNext:^(NSNumber *x) {
    @strongify(self);
    if (x.integerValue == CBManagerStatePoweredOn && ![OKCentralManager sharedInstance].isScanning) {
        [self _action_refresh:nil];
    }
}];

[[OKCentralManager sharedInstance].connectPeripheralConnection.signal subscribeNext:^(id  _Nullable x) {
    NSLog(@"Connection info: %@", x);
}];
```

## 扫描外设

`service uuid: 0x0000FEE9-0000-1000-8000-00805F9B34FB`

初始化`OKCentralManager`成功后，可以通过执行 `scanForPeripheralsCommand` 开始扫描外设

参数说明

|  功能 | 扫描外设 |
| ------------ | ------------ |
|  input | OKScanModel |

初始化扫描参数，具体参数内容可参考注释，默认超时时间 `30` 秒。

``` objectivec
OKScanModel *input = [[OKScanModel alloc] initModelWithServiceUUIDs:nil options:nil aScanInterval:30];
```

执行扫描指令后，指令返回的结果可从 `next` 中订阅，`error` 中可以处理扫描过程中遇到的错误

!> 为了实时更新扫描列表，在 `next` 信号中默认加了 `1.5 s` 的 `throttle`，否则会出现疯狂的信号值变化

示例代码

``` objectivec
@weakify(self);
self.dsp = [[[OKCentralManager sharedInstance].scanForPeripheralsCommand execute:input] subscribeNext:^(NSArray <OKPeripheral *> *peripherals) {
    @strongify(self);
    [self.okItems removeAllObjects];
    for (OKPeripheral *p in peripherals) {
        if (p.name.length) {
            [self.okItems addObject:p];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
} error:^(NSError * _Nullable error) {
    NSLog(@"%@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error.code == 4) {
            [SVProgressHUD showErrorWithStatus:@"蓝牙未开启"];
        }else if (error.code == kOKUtilsScanTimeoutErrorCode) {
            [SVProgressHUD showErrorWithStatus:@"扫描超时"];
        }
    });
}];
```
