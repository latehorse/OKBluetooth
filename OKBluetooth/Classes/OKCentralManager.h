//
//  OKCentralManager.h
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import <Foundation/Foundation.h>

@class RACCommand;
@class RACMulticastConnection;
@class CBCentralManager;

@interface OKScanModel : NSObject

/**
 * Scan will be stoped after input interaval. default is 30s.
 */
@property (nonatomic, assign) NSTimeInterval aScanInterval;

/**
 * An array of CBUUID objects that the app is interested in.
 * In this case, each CBUUID object represents the UUID of a service that
 * a peripheral is advertising.
 */
@property (nonatomic, strong) NSArray *serviceUUIDs;

/**
 * An optional dictionary specifying options to customize the scan.
 */
@property (nonatomic, strong) NSDictionary *options;

/**
 * Scans for nearby peripherals with criterias,
 * fills the - NSArray *peripherals.
 * Scan will be stoped after input interaval

 @param serviceUUIDs An array of CBUUID objects that the app is interested in.
 @param options An optional dictionary specifying options to customize the scan.
 @param aScanInterval Scan will be stoped after input interaval.
 @return A Model with scan options.
 */
- (instancetype)initModelWithServiceUUIDs:(NSArray *)serviceUUIDs options:(NSDictionary *)options aScanInterval:(NSTimeInterval)aScanInterval;

@end

/**
 * Wrapper class whicj implments common central role
 * over Core Bluetooth's CBCenteralManager instance
 */
@interface OKCentralManager : NSObject

/**
 * Indicates if CBCentralManager is scanning for peripheral
 */
@property (nonatomic, getter = isScanning) BOOL scanning;

/**
 * Indicates if central manager is readt for core bluetooth tasks. KVO observable.
 */
@property (assign, nonatomic, readonly, getter = isCentralReady) BOOL centralReady;

/**
 * Threshould to stop scanning for peripherals.
 * When the number of discovered peripherals exceeds this value, scanning will be
 * stopped even before the scan-interval
 */
@property (assign, nonatomic) NSUInteger peripheralsCountToStop;

/**
 * Human readable property that indicates why central manager is not ready, KVO observable.
 */
@property (weak, nonatomic, readonly) NSString *centralNotReadyReason;

/**
 * Peripherals that are nearby (sorted descending by RSSI values)
 */
@property (weak, nonatomic, readonly) NSArray *peripherals;

/**
 * Core bluetooth's Central manager, for implementing central role
 */
@property (strong, nonatomic, readonly) CBCentralManager *manager;

/**
 * CBCentralManager's state signal updated by centralManagerDidUpdateState:
 */
@property (strong, nonatomic, readonly) RACMulticastConnection *centralManagerStateConnection;

/**
 * Scans for nearby peripherals
 * and fills the - NSArray *peripherals
 * input @see OKScanModel
 */
@property (strong, nonatomic, readonly) RACCommand *scanForPeripheralsCommand;

/**
 * CBCentralManager's connection multicastConnection.
 */
@property (strong, nonatomic, readonly) RACMulticastConnection *connectPeripheralConnection;

/**
 * Stops ongoing scan proccess
 */
- (void)stopScanForPeripherals;

/**
 * Returns a list of known peripherals by their identifiers.
 * @param identifiers A list of peripheral identifiers (represented by NSUUID objects)
 * from which LGperipheral objects can be retrieved.
 * @return A list of peripherals that the central manager is able to match to the provided identifiers.
 */
- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;

/**
 * Returns a list of the peripherals (containing any of the specified services) currently connected to the system.
 * The list of connected peripherals can include those that are connected by other apps
 * and that will need to be connected locally using the connectPeripheral:options: method before they can be used.
 * @param serviceUUIDs A list of service UUIDs (represented by CBUUID objects).
 * @return A list of the LGPeripherals that are currently connected to
 * the system and that contain any of the services specified in the serviceUUID parameter.
 */
- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDS;

/**
 @return Singleton instance of Central manager
 */
+ (OKCentralManager *)sharedInstance;

@end
