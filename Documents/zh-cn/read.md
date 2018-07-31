读数据为了避免恶意调用读取，使用 `RAC` 后，执行 `command` 时，只有等上一个命令完成，才可以再次执行该命令，保证了消息顺序。

## 订阅通知

订阅通知这里，同时提供了一个 `notifyValueSignal`，便于其他业务直接通过订阅信号的方式，获取到数据。只需在搜索到服务以后，打开订阅模式即可。

代码示例

``` objectivec
[[okph.notifyValueCommand execute:@YES] subscribeNext:^(id  _Nullable x) {
    NSLog(@"notify: %@", x);
} error:^(NSError * _Nullable error) {
    NSLog(@"notifyError: %@", error);
}];
```

## 读取数据

读取指定特征值的数据，执行 `readValueCommand`，订阅读取结果

代码示例

``` objectivec
[[okph.readValueCommand execute:@0] subscribeNext:^(id  _Nullable x) {
    NSLog(@"readValue: %@", x);
}];
```
