//
//  OKViewController.m
//  OKBluetooth
//
//  Created by deadvia on 07/25/2018.
//  Copyright (c) 2018 deadvia. All rights reserved.
//

#import "OKViewController.h"
#import <OKBluetooth/OKBluetooth.h>

@interface OKViewController ()

@property (weak, nonatomic) IBOutlet UIButton *scanServiceBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *okActivityView;

@end

@implementation OKViewController

#pragma mark - Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    @weakify(self);
    [[OKCentralManager sharedInstance].scanForPeripheralsCommand.executing subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [self.okActivityView startAnimating];
        } else {
            [self.okActivityView stopAnimating];
        }
        
        NSLog(@"%@", [[OKCentralManager sharedInstance] peripherals]);
    }];
    
    [[[OKCentralManager sharedInstance].centralManagerStateConnection.signal distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        NSLog(@"\n%@    %@", x, [[OKCentralManager sharedInstance] centralNotReadyReason]);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
