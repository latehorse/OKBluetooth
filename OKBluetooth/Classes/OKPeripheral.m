//
//  OKPeripheral.m
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#elif TARGET_OS_MAC
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "OKPeripheral.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import "OKCentralManager.h"
#import "OKService.h"
#import "OKCharacteristic.h"
#import "OKUtils.h"

// Error Domains
NSString * const kOKPeripheralConnectionErrorDomain = @"OKPeripheralConnectionErrorDomain";

// Error Codes
const NSInteger kConnectionTimeoutErrorCode = 408;
const NSInteger kConnectionMissingErrorCode = 409;

NSString * const kConnectionTimeoutErrorMessage = @"BLE Device can't be connected by given interval";
NSString * const kConnectionMissingErrorMessage = @"BLE Device is not connected";

@interface OKPeripheral () <CBPeripheralDelegate>

/**
 * Peripheral's connect subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull connectServiceSubscriber;

/**
 * Peripheral's disConnect subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull disConnectServiceSubscriber;

/**
 * Peripheral's discoverServices subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull discoverServicesSubscriber;

/**
 * Peripheral's rssi subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull rssiValueSubscriber;

@end

@implementation OKPeripheral

/*----------------------------------------------------*/
#pragma mark - Getter/Setter -
/*----------------------------------------------------*/

- (BOOL)isConnected
{
    return (self.cbPeripheral.state == CBPeripheralStateConnected);
}

- (NSString *)UUIDString
{
    return [self.cbPeripheral.identifier UUIDString];
}

- (NSString *)name
{
    return [self.cbPeripheral name];
}

/*----------------------------------------------------*/
#pragma mark - Handler Methods -
/*----------------------------------------------------*/

- (void)handleConnectionWithError:(NSError *)anError
{
    _error = anError;
    OKLog(@"Connection with error - %@", anError);
    
    if (anError) {
        [self.connectServiceSubscriber sendError:anError];
    }else {
        [self.connectServiceSubscriber sendNext:self];
        [self.connectServiceSubscriber sendCompleted];
    }
}

- (void)handleDisconnectWithError:(NSError *)anError
{
    _error = anError;
    OKLog(@"Disconnect with error - %@", anError);
    
    if (anError) {
        [self.disConnectServiceSubscriber sendError:anError];
    }else {
        [self.disConnectServiceSubscriber sendNext:self];
        [self.disConnectServiceSubscriber sendCompleted];
    }
}

/*----------------------------------------------------*/
#pragma mark - Overide Methods -
/*----------------------------------------------------*/

- (NSString *)description
{
    NSString *org = [super description];
    
    return [org stringByAppendingFormat:@" UUIDString: %@", self.UUIDString];
}

/*----------------------------------------------------*/
#pragma mark - Error Generators -
/*----------------------------------------------------*/

- (NSError *)connectionErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kOKPeripheralConnectionErrorDomain
                               code:aCode
                           userInfo:@{kOKErrorMessageKey : aMsg}];
}

/*----------------------------------------------------*/
#pragma mark - Private Methods -
/*----------------------------------------------------*/

- (void)updateServiceWrappers
{
    NSMutableArray *updatedServices = [NSMutableArray new];
    for (CBService *service in self.cbPeripheral.services) {
        [updatedServices addObject:[[OKService alloc] initWithService:service]];
    }
    _services = updatedServices;
}

- (OKService *)wrapperByService:(CBService *)aService
{
    OKService *wrapper = nil;
    for (OKService *discovered in self.services) {
        if (discovered.cbService == aService) {
            wrapper = discovered;
            break;
        }
    }
    return wrapper;
}

#pragma mark - InitializeRAC -

- (void)initializeRAC
{
    @weakify(self);
    _connectCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(NSNumber *input) {
        @strongify(self);
        RACSubject *timeoutSubject = [RACSubject subject];
        RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            _connectServiceSubscriber = subscriber;
            [self.manager.manager connectPeripheral:self.cbPeripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                                                                CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                                                                CBConnectPeripheralOptionNotifyOnNotificationKey:@YES}];
            return [RACDisposable disposableWithBlock:^{
                [timeoutSubject sendCompleted];
                _connectServiceSubscriber = nil;
            }];
        }];
        
        // Subscribe command errors, then we can know the timeout
        [[timeoutSubject timeout:input.integerValue onScheduler:[RACScheduler mainThreadScheduler]] subscribeError:^(NSError * _Nullable error) {
            if (error.code == 1) {
                [self.connectServiceSubscriber sendError:[self connectionErrorWithCode:kConnectionTimeoutErrorCode message:kConnectionTimeoutErrorMessage]];
            }
        }];
        
        return signal;
    }];
    
    _disConnectCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        @strongify(self);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            _disConnectServiceSubscriber = subscriber;
            [self.manager.manager cancelPeripheralConnection:self.cbPeripheral];
            return [RACDisposable disposableWithBlock:^{
                _disConnectServiceSubscriber = nil;
            }];
        }];
    }];
    
    _discoverServicesCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(NSArray *input) {
        @strongify(self);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            if (!self.isConnected) {
                [subscriber sendError:[self connectionErrorWithCode:kConnectionMissingErrorCode message:kConnectionMissingErrorMessage]];
                return nil;
            }
            
            _discoverServicesSubscriber = subscriber;
            [self.cbPeripheral discoverServices:input];
            return [RACDisposable disposableWithBlock:^{
                _discoverServicesSubscriber = nil;
            }];
        }];
    }];
    
    _readRSSIValueCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        @strongify(self);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            _rssiValueSubscriber = subscriber;
            [self.cbPeripheral readRSSI];
            return [RACDisposable disposableWithBlock:^{
                _rssiValueSubscriber = nil;
            }];
        }];
    }];
    
    _rssiSignal = RACObserve(self, RSSI);
    RAC(self, discoveringServices) = [self.discoverServicesCommand executing];
}

/*----------------------------------------------------*/
#pragma mark - CBPeripheral Delegate -
/*----------------------------------------------------*/

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    _discoveringServices = NO;
    [self updateServiceWrappers];
    
#if OK_ENABLE_BLE_LOGGING != 0
    for (OKService *aService in self.services) {
        OKLog(@"Service discovered - %@", aService.cbService.UUID);
    }
#endif
    
    if (error) {
        [self.discoverServicesSubscriber sendError:error];
    }else {
        [self.discoverServicesSubscriber sendNext:self];
        [self.discoverServicesSubscriber sendCompleted];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self wrapperByService:service] handleDiscoveredCharacteristics:service.characteristics
                                                                   error:error];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSData *value = [characteristic.value copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self wrapperByService:characteristic.service]
          wrapperByCharacteristic:characteristic]
         handleReadValue:value error:error];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self wrapperByService:characteristic.service]
          wrapperByCharacteristic:characteristic]
         handleSetNotifiedWithError:error];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self wrapperByService:characteristic.service]
          wrapperByCharacteristic:characteristic]
         handleWrittenValueWithError:error];
    });
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error) {
        [self.rssiValueSubscriber sendError:error];
    }else {
        [self.rssiValueSubscriber sendNext:peripheral.RSSI];
        [self.rssiValueSubscriber sendCompleted];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    if (error) {
        [self.rssiValueSubscriber sendError:error];
    }else {
        [self.rssiValueSubscriber sendNext:peripheral.RSSI];
        [self.rssiValueSubscriber sendCompleted];
    }
}

/*----------------------------------------------------*/
#pragma mark - Lifecycle -
/*----------------------------------------------------*/

- (instancetype)initWithPeripheral:(CBPeripheral *)aPeripheral manager:(OKCentralManager *)manager
{
    if (self = [super init]) {
        _cbPeripheral = aPeripheral;
        _cbPeripheral.delegate = self;
        _manager = manager;
        [self initializeRAC];
    }
    return self;
}

@end
