## 连接设备

在扫描到需要连接的设备后，通过 `connectCommand` 命令，开始连接服务。`input` 为连接的超时时间

示例代码

``` objectivec
@weakify(self);
[[_clickBtn rac_signalForControlEvents:UIControlEventTouchUpInside]
 subscribeNext:^(__kindof UIControl * _Nullable x) {
     @strongify(self);
     if (self.peripheral.isConnected) {
         [[self.peripheral.disConnectCommand execute:@1] subscribeNext:^(id  _Nullable x) {
             
         } error:^(NSError * _Nullable error) {
             NSLog(@"%@", error);
         } completed:^{
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.peripheral = _peripheral;
             });
         }];
     }else {
         [SVProgressHUD showWithStatus:@"连接中"];
         [[self.peripheral.connectCommand execute:@30] subscribeNext:^(id  _Nullable x) {
             
         } error:^(NSError * _Nullable error) {
             NSLog(@"%@", error);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [SVProgressHUD dismiss];
             });
         } completed:^{
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.peripheral = _peripheral;
                 [SVProgressHUD dismiss];
             });
         }];
     }
 }];
```

!> 另外，`OKPeripheral` 提供一个 `RSSI` 订阅服务，信号强度的变化，会通过该信号发布。

## 扫描服务

连接成功后，可以开始搜索设备的服务信息，执行 `discoverServicesCommand` 命令，`input` 表示过滤的 `serviceUUIDs` 数组，默认为空。

!> 最终搜索到的服务，会存放在 `OKPeripheral` 属性下

示例代码

``` objectivec
[[self.okph.discoverServicesCommand execute:@[]] subscribeNext:^(OKPeripheral *x) {
    [self.okItems removeAllObjects];
    [self.okItems addObjectsFromArray:x.services];
} error:^(NSError * _Nullable error) {
    NSLog(@"%@", error);
} completed:^{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}];
```
 
## 搜索特征

在搜索到的服务中，执行 `discoverCharacteristicsCommand` 命令，即可搜索指定服务的特征值，便于后续订阅通知，读写数据操作

代码示例

```
[[self.service.discoverCharacteristicsCommand execute:@[]] subscribeNext:^(OKService *x) {
    [self.okItems removeAllObjects];
    [self.okItems addObjectsFromArray:x.characteristics];
} error:^(NSError * _Nullable error) {
    NSLog(@"%@", error);
} completed:^{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}];
```

至此，连接的基本功能就介绍完了
