//
//  OKPeripheralViewController.m
//  OKBluetooth_Example
//
//  Created by yuhanle on 2018/7/30.
//  Copyright © 2018年 deadvia. All rights reserved.
//

#import "OKPeripheralViewController.h"
#import <OKBluetooth/OKBluetooth.h>
#import "OKCharactersViewController.h"

@interface OKPeripheralViewController ()

@property (strong, nonatomic) NSMutableArray *okItems;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation OKPeripheralViewController

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
    // Do any additional setup after loading the view.
    
    self.title = self.okph.name;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peripheral" forIndexPath:indexPath];
    OKService *okph = [self.okItems objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", okph];
    cell.detailTextLabel.text = okph.UUIDString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedIndexPath = indexPath;
    
    [self performSegueWithIdentifier:@"characteristic" sender:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.destinationViewController isKindOfClass:[OKCharactersViewController class]]) {
        ((OKCharactersViewController *)segue.destinationViewController).service = [self.okItems objectAtIndex:self.selectedIndexPath.row];
        self.selectedIndexPath = nil;
    }
}

@end
