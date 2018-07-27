//
//  OKPeripheral.h
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import <Foundation/Foundation.h>

@class CBPeripheral;
@class OKCentralManager;
@class RACCommand;
@class RACSignal;
@class RACMulticastConnection;
@protocol RACSubscriber;

#pragma mark - Error Domains -

/**
 * Error domains for Connection errors
 */
extern NSString * const kOKPeripheralConnectionErrorDomain;

#pragma mark - Error Codes -
/**
 * Connection timeout error code
 */
extern const NSInteger kConnectionTimeoutErrorCode;

/**
 * Connection missing error code
 */
extern const NSInteger kConnectionMissingErrorCode;

#pragma mark - Error Messages -

/**
 * Error message for connection timeouts
 */
extern NSString * const kConnectionTimeoutErrorMessage;

/**
 * Error message for missing connections
 */
extern NSString * const kConnectionMissingErrorMessage;

@interface OKPeripheral : NSObject

/**
 * Core Bluetooth's CBPeripheral instance
 */
@property (strong, nonatomic, readonly) CBPeripheral *cbPeripheral;

/**
 * OKCentralManager's instance used to connect to peripherals
 */
@property (unsafe_unretained, nonatomic, readonly) OKCentralManager *manager;

/**
 * Flag to indicate discovering services or not
 */
@property (assign, nonatomic, readonly, getter = isDiscoveringServices) BOOL discoveringServices;

/**
 * Available services for this service,
 * will be updated after calling discoverServicesWithCompletion:
 */
@property (strong, nonatomic, readonly) NSArray *services;

/**
 * UUID Identifier of peripheral
 */
@property (weak, nonatomic, readonly) NSString *UUIDString;

/**
 * Name of peripheral
 */
@property (weak, nonatomic, readonly) NSString *name;

/**
 * Sinal strength of peripheral
 */
@property (assign, nonatomic) NSInteger RSSI;

/**
 * The advertisement data that was tracked from peripheral
 */
@property (strong, nonatomic) NSDictionary *advertisingData;

/**
 * The error data when connect/disconnect. Default is nil
 */
@property (strong, nonatomic, readonly) NSError *error;

/**
 * Opens connection to this peripheral
 * input aWatchDogInterval timeout after which, connection will be closed (if it was in stage isConnecting)
 */
@property (nonatomic, strong, readonly) RACCommand *connectCommand;

/**
 * Disconnects from peripheral peripheral
 */
@property (nonatomic, strong, readonly) RACCommand *disConnectCommand;

/**
 * Discoveres All services of this peripheral
 * input serviceUUIDs Array of CBUUID's that contain service UUIDs which we need to discover
 */
@property (nonatomic, strong, readonly) RACCommand *discoverServicesCommand;

/**
 * Reads current RSSI of this peripheral, (note : requires active connection to peripheral)
 */
@property (nonatomic, strong, readonly) RACCommand *readRSSIValueCommand;

/**
 * Current RSSI of this peripheral, (note : requires active connection to peripheral)
 */
@property (nonatomic, strong, readonly) RACSignal *rssiSignal;

#pragma mark - Private Handlers -

// ----- Used for input events -----/

- (void)handleConnectionWithError:(NSError *)anError;

- (void)handleDisconnectWithError:(NSError *)anError;

#pragma mark - Private Initializer -
/**
 * @return Wrapper object over Core Bluetooth's CBPeripheral
 */
- (instancetype)initWithPeripheral:(CBPeripheral *)aPeripheral manager:(OKCentralManager *)manager;

@end
