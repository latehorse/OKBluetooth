本项目提供了长数据的写操作，在内部实现了一个 `loop` 操作，分包写入，目前固定包的大小是 `20` 字节

## 写入数据

先定义一个写入参数，并把数据赋值，在执行 `writeValueCommand` 命令

``` objectivec
OKWriteValueModel *model = [[OKWriteValueModel alloc] init];
model.type = CBCharacteristicWriteWithoutResponse;

Byte byte[] = {1, 3};
model.data = [NSData dataWithBytes:byte length:2];

[[okph.writeValueCommand execute:model] subscribeNext:^(id  _Nullable x) {
    NSLog(@"writeValue: %@", x);
} error:^(NSError * _Nullable error) {
    NSLog(@"writeValue: %@", error);
} completed:^{
    NSLog(@"writeSuccess");
}];
```

!> 如果是较大的数据包，可以从 `next` 中订阅到当前发送的进度，返回是 `OKWriteValueModel` 的实例，可以根据 `offset` 计算。
