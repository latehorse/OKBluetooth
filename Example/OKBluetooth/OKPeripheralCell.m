//
//  OKPeripheralCell.m
//  OKBluetooth_Example
//
//  Created by yuhanle on 2018/7/30.
//  Copyright © 2018年 deadvia. All rights reserved.
//

#import "OKPeripheralCell.h"
#import <OKBluetooth/OKBluetooth.h>
#import <SVProgressHUD/SVProgressHUD.h>

@implementation OKPeripheralCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setPeripheral:(OKPeripheral *)peripheral {
    _peripheral = peripheral;
    
    _nameLabel.text = [NSString stringWithFormat:@"name: %@", peripheral.name.length ? peripheral.name : @"NONAME"];
    _uuidLabel.text = [NSString stringWithFormat:@"uuid: %@", peripheral.UUIDString];
    _rssiLabel.text = [NSString stringWithFormat:@"RSSI: %@", @(peripheral.RSSI)];
    
    if (peripheral.isConnected) {
        [_clickBtn setTitle:@"断开连接" forState:UIControlStateNormal];
    }else {
        [_clickBtn setTitle:@"连接" forState:UIControlStateNormal];
    }
}

@end
