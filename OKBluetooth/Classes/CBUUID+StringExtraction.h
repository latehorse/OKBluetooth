//
//  CBUUID+StringExtraction.h
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/27.
//

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#elif TARGET_OS_MAC
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface CBUUID (StringExtraction)

/**
 * Converts 16bit and 128bit CBUUID to NSString representation
 * @return NSString representation of CBUUID
 */
- (NSString *)representativeString;

@end
