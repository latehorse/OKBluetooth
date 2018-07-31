## 断开设备

需要断开连接时，通过 `disConnectCommand` 命令，执行断开。`input` 没有意义

示例

```objectivec
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

!> 如果是异常断开，你需要到连接信号的订阅中，手动调用一次 `connect` 才可以顺利实现自动重连的功能