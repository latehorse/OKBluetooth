断开自动重连的实现，即在收到断开连接消息时，调用提供的`connect` 方法，手机端会持续连接该设备直至连接成功为止。

自动重连的方法类似，是在收到异常断开连接的回调中，调用底层 `connect` 的方法，在下次靠近设备时，系统会帮助APP 自动重连。

在以上自动重连的过程中，会存在几个问题：

* 下次靠近设备的时间不确定，可能在靠近的时间，设备已经被其他方式解绑，此时重连设备是不合理的；
* 其他类似上面的场景，都会存在重连设备不合理的问题。

### 安卓问题：

* 后台重连时间过长（10s左右）

### iOS 问题：

* 在用户手动kill 掉应用，概率性无法连接成功，需要打开APP 后重新连接
* 重连时间过长（10s左右）

### 利用连接 Peripheral 时的选项

Foreground-Only app 在挂起的时候，便会加入到系统的一个队列中，当程序重新唤醒时，系统便会通知程序。Core Bluetooth 会在程序中包含 central 时，给用户以提示。用户可根据提示来判断是否要唤醒该 app。

你可以利用 central 在连接 peripheral 时的方法 `connectPeripheral:options:` 中的 `options `来触发提示：

* `CBConnectPeripheralOptionNotifyOnConnectionKey` —— 在连接成功后，程序被挂起，给出系统提示。
* `CBConnectPeripheralOptionNotifyOnDisconnectionKey` —— 在程序挂起，蓝牙连接断开时，给出系统提示。
* `CBConnectPeripheralOptionNotifyOnNotificationKey` —— 在程序挂起后，收到 peripheral 数据时，给出系统提示。

### Core Bluetooth 后台模式

如果你想让你的 app 能在后台运行蓝牙，那么必须在 info.plist 中打开蓝牙的后台运行模式。当配置之后，收到相关事件便会从后台唤醒。这一机制对定期接收数据的 app 很有用，比如心率监测器。

### 作为 Central 的后台模式

如果在 info.plist 中配置了 UIBackgroundModes – bluetooth-central，那么系统则允许程序在后台处理蓝牙相关事件。在程序进入后台后，依然能扫描、搜索 peripheral，并且还能进行数据交互。当 CBCentralManagerDelegate 和 CBPeripheralDelegate 的代理方法被调用时，系统将会唤醒程序。此时允许你去处理重要的事件，比如：连接的建立或断开，peripheral 发送了数据，central manager 的状态改变。

虽然此时程序能在后台运行，但是对 peripheral 的扫描和在前台时是不一样的。实际情况是这样的：

* 设置的 `CBCentralManagerScanOptionAllowDuplicatesKey` 将失效，并将发现的多个 peripheral 广播的事件合并为一个。
* 如果全部的 app 都在后台搜索 peripheral，那么每次搜索的时间间隔会更大。这会导致搜索到 peripheral 的时间变长。

这些相应的调整会减少无线电使用，并提升续航能力。

### 巧妙的使用后台模式

虽然程序支持一个或多个 Core Bluetooth 服务在后台运行，但也不要滥用。因为蓝牙服务会占用 iOS 设备的无线电资源，这也会间接影响到续航能力，所以尽可能少的去使用后台模式。app 会唤醒程序并处理相关事务，完成后又会快速回到挂起状态。

无论是 central 还是 peripheral，要支持后台模式都应该遵循以下几点：

* 程序应该提供 UI，让用户决定是否要在后台运行。
* 一旦程序在后台被唤醒，程序只有 10s 的时间来处理相关事务。所以应该在程序再次挂起前处理完事件。后台运行的太耗时的程序会被系统强制关闭进程。
* 处理无关的事件不应该唤醒程序。

和后台运行的更多介绍，可以查看 [App Programming Guide for iOS](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007072)。