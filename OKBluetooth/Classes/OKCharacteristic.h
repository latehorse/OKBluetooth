//
//  OKCharacteristic.h
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class CBCharacteristic;
@class RACCommand;
@class RACSignal;
@protocol RACSubscriber;

@interface OKWriteValueModel : NSObject

/**
 * Write time. Default is 30s.
 */
@property (nonatomic, assign) NSTimeInterval aInterval;

/**
 * The Data will be send.
 */
@property (nonatomic, strong) NSData *data;

/**
 * Write type. Default is @see CBCharacteristicWriteWithoutResponse.
 */
@property (nonatomic, assign) CBCharacteristicWriteType type;

/**
 * Written data length
 */
@property (nonatomic, assign) NSInteger offset;

/**
 * Identifier more data to write.
 */
@property (nonatomic, assign, getter = hasMore, readonly) BOOL more;

/**
 * Sub data

 @return NSData
 */
- (NSData *)subData;

@end

@interface OKCharacteristic : NSObject

/**
 * Core Bluetooth's CBCharacteristic instance
 */
@property (strong, nonatomic, readonly) CBCharacteristic *cbCharacteristic;

/**
 * NSString representation of 16/128 bit CBUUID
 */
@property (strong, nonatomic, readonly) NSString *UUIDString;

/**
 * Enables or disables notifications/indications for the characteristic
 * value of characteristic.
 * input Enable/Disable notifications
 * SubscriberNext will return the latest value
 */
@property (nonatomic, strong, readonly) RACCommand *notifyValueCommand;

/**
 * Writes input data to characteristic
 * input @see OKWriteValueModel object representing bytes that needs to be written
 */
@property (nonatomic, strong, readonly) RACCommand *writeValueCommand;

/**
 * Reads characteristic value
 * input null
 */
@property (nonatomic, strong, readonly) RACCommand *readValueCommand;

/**
 * NotifyValue update
 */
@property (nonatomic, strong) RACSignal *notifyValueSignal;

// ----- Used for input events -----/

- (void)handleSetNotifiedWithError:(NSError *)anError;

- (void)handleReadValue:(NSData *)aValue error:(NSError *)anError;

- (void)handleWrittenValueWithError:(NSError *)anError;

/**
 * @return Wrapper object over Core Bluetooth's CBCharacteristic
 */
- (instancetype)initWithCharacteristic:(CBCharacteristic *)aCharacteristic;

@end
