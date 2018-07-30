//
//  OKCentralManager.m
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import "OKCentralManager.h"

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#elif TARGET_OS_MAC
#import <IOBluetooth/IOBluetooth.h>
#endif
#import "OKPeripheral.h"
#import "OKUtils.h"
#import <ReactiveObjC/ReactiveObjC.h>

@implementation OKScanModel

- (instancetype)init {
    if (self = [super init]) {
        self.options = @{CBCentralManagerScanOptionAllowDuplicatesKey : @YES};
        self.aScanInterval = 30;
    }
    return self;
}

- (instancetype)initModelWithServiceUUIDs:(NSArray *)serviceUUIDs options:(NSDictionary *)options aScanInterval:(NSTimeInterval)aScanInterval {
    if (self = [super init]) {
        self.options = options ? options : @{CBCentralManagerScanOptionAllowDuplicatesKey : @NO};
        self.aScanInterval = aScanInterval ? aScanInterval : 30;
        self.serviceUUIDs = serviceUUIDs;
    }
    return self;
}

@end

@interface OKCentralManager () <CBCentralManagerDelegate>

/**
 * Ongoing operations
 */
@property (strong, atomic) NSMutableDictionary *operations;

/**
 * CBCentralManager's dispatch queue
 */
@property (strong, nonatomic) dispatch_queue_t centralQueue;

/**
 * List of scanned peripherals
 */
@property (strong, nonatomic) NSMutableArray *scannedPeripherals;
/**
 * CBCentralManager's state updated by centralManagerDidUpdateState:
 */
@property(nonatomic) CBCentralManagerState cbCentralManagerState;

/**
 * CBCentralManager scanService's subscriber
 */
@property (nonatomic, strong) id<RACSubscriber> _Nonnull scanServiceSubscriber;

/**
 * CBCentralManager connectService's subscriber
 */
@property (nonatomic, strong) id<RACSubscriber> _Nonnull connectServiceSubscriber;

@end

@implementation OKCentralManager

/*----------------------------------------------------*/
#pragma mark - Getter/Setter -
/*----------------------------------------------------*/

- (BOOL)isCentralReady
{
    return (self.manager.state == CBCentralManagerStatePoweredOn);
}

- (NSString *)centralNotReadyReason
{
    return [self stateMessage];
}

- (NSArray *)peripherals
{
    // Sorting OKPeripherals by RSSI values
    NSArray *sortedArray;
    sortedArray = [_scannedPeripherals sortedArrayUsingComparator:^NSComparisonResult(OKPeripheral *a, OKPeripheral *b) {
        return a.RSSI < b.RSSI;
    }];
    return sortedArray;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central
{
    self.cbCentralManagerState = central.state;
    NSString *message = [self stateMessage];
    if (message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            OKLogError(@"%@", message);
        });
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    OKPeripheral *okPeripheral = [self wrapperByPeripheral:peripheral];
    if (!okPeripheral.RSSI) {
        okPeripheral.RSSI = [RSSI integerValue];
    } else {
        // Calculating AVG RSSI
        okPeripheral.RSSI = okPeripheral.RSSI * [RSSI integerValue] / 2;
    }
    okPeripheral.advertisingData = advertisementData;
    
    [self.scanServiceSubscriber sendNext:self.peripherals];
    if (self.scannedPeripherals.count >= self.peripheralsCountToStop) {
        [self.scanServiceSubscriber sendCompleted];
        [self stopScanForPeripherals];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    OKPeripheral *okPeripheral = [self wrapperByPeripheral:peripheral];
    [okPeripheral handleConnectionWithError:nil];
    
    [self.connectServiceSubscriber sendNext:okPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    OKPeripheral *okPeripheral = [self wrapperByPeripheral:peripheral];
    [okPeripheral handleConnectionWithError:error];
    
    [self.connectServiceSubscriber sendNext:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    OKPeripheral *okPeripheral = [self wrapperByPeripheral:peripheral];
    [okPeripheral handleDisconnectWithError:error];
    
    [self.connectServiceSubscriber sendNext:peripheral];
    //[self.scannedPeripherals removeObject:okPeripheral];
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    [[self wrappersByPeripherals:peripherals] enumerateObjectsUsingBlock:^(OKPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.manager.manager connectPeripheral:obj.cbPeripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                                                          CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                                                          CBConnectPeripheralOptionNotifyOnNotificationKey:@YES}];
        [self.connectServiceSubscriber sendNext:obj];
    }];
}

/*----------------------------------------------------*/
#pragma mark - Public Methods -
/*----------------------------------------------------*/
- (void)stopScanForPeripherals
{
    self.scanning = NO;
    [self.manager stopScan];
}

- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    return [self wrappersByPeripherals:[self.manager retrievePeripheralsWithIdentifiers:identifiers]];
}

- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDS
{
    return [self wrappersByPeripherals:[self.manager retrieveConnectedPeripheralsWithServices:serviceUUIDS]];
}

/*----------------------------------------------------*/
#pragma mark - Private Methods -
/*----------------------------------------------------*/

- (NSString *)stateMessage
{
    NSString *message = nil;
    switch (self.manager.state) {
        case CBCentralManagerStateUnsupported:
            message = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            message = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnknown:
            message = @"Central not initialized yet.";
            break;
        case CBCentralManagerStatePoweredOff:
            message = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            message = @"";
            break;
        default:
            message = @"";
            break;
    }
    return message;
}

- (OKPeripheral *)wrapperByPeripheral:(CBPeripheral *)aPeripheral
{
    OKPeripheral *wrapper = nil;
    for (OKPeripheral *scanned in self.scannedPeripherals) {
        if (scanned.cbPeripheral == aPeripheral) {
            wrapper = scanned;
            break;
        }
    }
    if (!wrapper) {
        wrapper = [[OKPeripheral alloc] initWithPeripheral:aPeripheral manager:self];
        [self.scannedPeripherals addObject:wrapper];
    }
    return wrapper;
}

- (NSArray *)wrappersByPeripherals:(NSArray *)peripherals
{
    NSMutableArray *okPeripherals = [NSMutableArray new];
    
    for (CBPeripheral *peripheral in peripherals) {
        [okPeripherals addObject:[self wrapperByPeripheral:peripheral]];
    }
    return okPeripherals;
}

#pragma mark - InitializeRAC -
- (void)initializeRAC
{
    @weakify(self);
    RACSignal *centralManagerStateSingal = [RACObserve(self, cbCentralManagerState) doNext:^(NSNumber *x) {
        @strongify(self);
        if (x.integerValue != CBCentralManagerStatePoweredOn) {
            if (self.scanServiceSubscriber) {
                [self.scanServiceSubscriber sendError:[OKUtils scanErrorWithCode:self.cbCentralManagerState message:[self stateMessage]]];
                self.scanServiceSubscriber = nil;
            }
        }
    }];
    RACSignal *connectPeripheralSignal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        self.connectServiceSubscriber = subscriber;
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    _centralManagerStateConnection = [centralManagerStateSingal publish];
    _connectPeripheralConnection = [connectPeripheralSignal publish];
    [_centralManagerStateConnection connect];
    [_connectPeripheralConnection connect];
    
    _scanForPeripheralsCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(OKScanModel * _Nonnull input) {
        RACSubject *timoutSubject = [RACSubject subject];
        RACSignal *scanSignal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            @strongify(self);
            if (self.cbCentralManagerState != CBCentralManagerStatePoweredOn) {
                [timoutSubject sendCompleted];
                [subscriber sendError:[OKUtils scanErrorWithCode:self.cbCentralManagerState message:[self stateMessage]]];
                return nil;
            }
            
            [self.scannedPeripherals removeAllObjects];
            [self.manager scanForPeripheralsWithServices:input.serviceUUIDs options:input.options];
            self.scanServiceSubscriber = subscriber;
            return [RACDisposable disposableWithBlock:^{
                [timoutSubject sendCompleted];
                [self stopScanForPeripherals];
            }];
        }];
        
        // Subscribe command errors, then we can know the timeout
        [[timoutSubject timeout:input.aScanInterval onScheduler:[RACScheduler mainThreadScheduler]] subscribeError:^(NSError * _Nullable error) {
            if (error.code == 1) {
                if (self.scanServiceSubscriber) {
                    [self.scanServiceSubscriber sendError:[OKUtils scanErrorWithCode:kOKUtilsScanTimeoutErrorCode message:kOKUtilsScanTimeoutErrorMessage]];
                    self.scanServiceSubscriber = nil;
                }
            }
        }];
        
        return [scanSignal throttle:1.5];
    }];
    
    RAC(self, scanning) = [self.scanForPeripheralsCommand executing];
}

/*----------------------------------------------------*/
#pragma mark - LifeCycle -
/*----------------------------------------------------*/

static OKCentralManager *sharedInstance = nil;

+ (OKCentralManager *)sharedInstance
{
    // Thread blocking to be sure for singleton instance
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [OKCentralManager new];
            [sharedInstance initializeRAC];
        }
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _centralQueue = dispatch_queue_create("com.OKBluetooth.OKCentralQueue", DISPATCH_QUEUE_SERIAL);
        _manager      = [[CBCentralManager alloc] initWithDelegate:self queue:self.centralQueue options:@{ CBCentralManagerOptionRestoreIdentifierKey: @"com.OKBluetooth.restoreIdentifier" }];
        _cbCentralManagerState = _manager.state;
        _scannedPeripherals = [NSMutableArray new];
        _peripheralsCountToStop = NSUIntegerMax;
    }
    return self;
}

@end
