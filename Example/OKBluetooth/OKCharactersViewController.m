//
//  OKCharactersViewController.m
//  OKBluetooth_Example
//
//  Created by yuhanle on 2018/7/30.
//  Copyright © 2018年 deadvia. All rights reserved.
//

#import "OKCharactersViewController.h"
#import <OKBluetooth/OKBluetooth.h>

//服务
NSString * const kDevControllServiceUUIDString                 = @"0000FEE9-0000-1000-8000-00805F9B34FB";
NSString * const kDevOTAServiceUUIDString                      = @"FEE8";

NSString * const kDevDeviceWriteCharacteristicUUIDString       = @"D44BC439-ABFD-45A2-B575-925416129600";
NSString * const kDevDeviceReadCharacteristicUUIDString        = @"D44BC439-ABFD-45A2-B575-925416129601";
NSString * const kDevDeviceVersionCharacteristicUUIDString     = @"D44BC439-ABFD-45A2-B575-925416129602";
NSString * const kDevDeviceInfoCharacteristicUUIDString        = @"D44BC439-ABFD-45A2-B575-925416129603";
NSString * const kDevDeviceStateCharacteristicUUIDString       = @"D44BC439-ABFD-45A2-B575-925416129604";
NSString * const kDevDeviceConnectInfoCharacteristicUUIDString = @"D44BC439-ABFD-45A2-B575-925416129605";

@interface OKCharactersViewController ()

@property (strong, nonatomic) NSMutableArray *okItems;
@property (strong, nonatomic) RACDisposable *notifyRACDisposable;

@end

@implementation OKCharactersViewController

- (void)dealloc {
    [self.notifyRACDisposable dispose];
}

#pragma mark - Lazy load
- (NSMutableArray *)okItems {
    if (!_okItems) {
        _okItems = [[NSMutableArray alloc] init];
    }
    return _okItems;
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.okItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"characteristic" forIndexPath:indexPath];
    OKCharacteristic *okph = [self.okItems objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", okph];
    cell.detailTextLabel.text = okph.UUIDString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OKCharacteristic *okph = [self.okItems objectAtIndex:indexPath.row];
    if ([[okph.UUIDString uppercaseString] isEqualToString:kDevDeviceWriteCharacteristicUUIDString]) {
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
    }
    
    if ([[okph.UUIDString uppercaseString] isEqualToString:kDevDeviceReadCharacteristicUUIDString]) {
        [[okph.readValueCommand execute:@0] subscribeNext:^(id  _Nullable x) {
            NSLog(@"readValue: %@", x);
        }];
    }
    
    if ([[okph.UUIDString uppercaseString] isEqualToString:kDevDeviceReadCharacteristicUUIDString]) {
        [[okph.notifyValueCommand execute:@YES] subscribeNext:^(id  _Nullable x) {
            NSLog(@"notify: %@", x);
        } error:^(NSError * _Nullable error) {
            NSLog(@"notifyError: %@", error);
        }];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
