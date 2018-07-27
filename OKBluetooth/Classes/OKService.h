//
//  OKService.h
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import <Foundation/Foundation.h>

@class CBCharacteristic;
@class CBService;
@class CBPeripheral;
@class OKCharacteristic;
@class RACCommand;
@class RACSignal;
@protocol RACSubscriber;

@interface OKService : NSObject

/**
 * Core Bluetooth's CBService instance
 */
@property (strong, nonatomic, readonly) CBService *cbService;

/**
 * Core Bluetooth's CBPeripheral isntance, which this instance belongs
 */
@property (unsafe_unretained, nonatomic, readonly) CBPeripheral *cbPeripheral;

/**
 * NSString representation of 16/128 bit CBUUID
 */
@property (weak, nonatomic, readonly) NSString *UUIDString;

/**
 * Flag to indicate discovering characteristics or not
 */
@property (assign, nonatomic, readonly, getter = idDiscoveringCharacteristics) BOOL discoveringCharacteristics;

/**
 * Availabel characteristics for this service,
 * will be updated after discoverCharacteristicsWithCompletion: call
 */
@property (strong, nonatomic) NSArray *characteristics;

/**
 * Discoveres Input characteristics of this service
 * input uuids Array of CBUUID's that contain characteristic UUIDs which
 * we need to discover
 */
@property (strong, nonatomic, readonly) RACCommand *discoverCharacteristicsCommand;

// ----- Used for input events -----/

- (void)handleDiscoveredCharacteristics:(NSArray *)aCharacteristics error:(NSError *)aError;

/**
 * Used for input events

 @param aChar CBCharacteristic
 @return OKCharacteristic
 */
- (OKCharacteristic *)wrapperByCharacteristic:(CBCharacteristic *)aChar;

/**
 * @return Wrapper object over Core Bluetooth's CBService
 */
- (instancetype)initWithService:(CBService *)aService;

@end
