//
//  OKListViewController.m
//  OKBluetooth_Example
//
//  Created by yuhanle on 2018/7/27.
//  Copyright © 2018年 deadvia. All rights reserved.
//

#import "OKListViewController.h"
#import <OKBluetooth/OKBluetooth.h>

@interface OKListViewController ()

@property (strong, nonatomic) RACDisposable *dsp;
@property (strong, nonatomic) NSMutableArray *okItems;

@end

@implementation OKListViewController

- (void)dealloc {
    [self.dsp dispose];
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
    
    [OKCentralManager sharedInstance].peripheralsCountToStop = 10;
    OKScanModel *input = [[OKScanModel alloc] initModelWithServiceUUIDs:nil options:nil aScanInterval:30];
    
    @weakify(self);
    self.dsp = [[[OKCentralManager sharedInstance].scanForPeripheralsCommand execute:input] subscribeNext:^(NSArray <OKPeripheral *> *peripherals) {
        @strongify(self);
        [self.okItems removeAllObjects];
        [self.okItems addObjectsFromArray:peripherals];
        
        NSLog(@"%@", self.okItems);
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"okperipheral" forIndexPath:indexPath];
    OKPeripheral *okph = [self.okItems objectAtIndex:indexPath.row];
    cell.textLabel.text = okph.name;
    cell.detailTextLabel.text = okph.UUIDString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OKPeripheral *okph = [self.okItems objectAtIndex:indexPath.row];
    [[okph.connectCommand execute:@30] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    }];
}

@end
