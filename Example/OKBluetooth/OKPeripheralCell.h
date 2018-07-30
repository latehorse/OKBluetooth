//
//  OKPeripheralCell.h
//  OKBluetooth_Example
//
//  Created by yuhanle on 2018/7/30.
//  Copyright © 2018年 deadvia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OKPeripheral;

@interface OKPeripheralCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *clickBtn;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;

@property (strong, nonatomic) OKPeripheral *peripheral;

@end
