//
//  OKListViewController.m
//  OKBluetooth_Example
//
//  Created by yuhanle on 2018/7/27.
//  Copyright © 2018年 deadvia. All rights reserved.
//

#import "OKListViewController.h"
#import <OKBluetooth/OKBluetooth.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "OKPeripheralCell.h"
#import "OKPeripheralViewController.h"

@interface OKListViewController ()

@property (assign, nonatomic) BOOL hasAppear;
@property (strong, nonatomic) RACDisposable *dsp;
@property (strong, nonatomic) NSMutableArray *okItems;

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation OKListViewController

- (void)dealloc {
    [self.dsp dispose];
}

- (IBAction)_action_refresh:(UIBarButtonItem *)sender {
    [self.okItems removeAllObjects];
    [self.tableView reloadData];
    
    OKScanModel *input = [[OKScanModel alloc] initModelWithServiceUUIDs:nil options:nil aScanInterval:10];
    
    @weakify(self);
    self.dsp = [[[OKCentralManager sharedInstance].scanForPeripheralsCommand execute:input] subscribeNext:^(OKPeripheral *peripheral) {
        @strongify(self);
        [self.okItems removeAllObjects];
        [self.okItems addObjectsFromArray:[OKCentralManager sharedInstance].peripherals];
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
    
    [OKCentralManager sharedInstance].peripheralsCountToStop = 30;
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.hasAppear) {
        [self _action_refresh:nil];
    }
    self.hasAppear = YES;
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
    OKPeripheralCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OKPeripheralCell" forIndexPath:indexPath];
    OKPeripheral *okph = [self.okItems objectAtIndex:indexPath.row];
    cell.peripheral = okph;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedIndexPath = indexPath;
    
    [self performSegueWithIdentifier:@"SeePeripheralSegue" sender:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     
     if ([segue.destinationViewController isKindOfClass:[OKPeripheralViewController class]]) {
         ((OKPeripheralViewController *)segue.destinationViewController).okph = [self.okItems objectAtIndex:self.selectedIndexPath.row];
         self.selectedIndexPath = nil;
     }
 }

@end
