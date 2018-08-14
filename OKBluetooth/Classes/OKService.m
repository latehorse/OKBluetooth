//
//  OKService.m
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import "OKService.h"

#import "CBUUID+StringExtraction.h"
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#elif TARGET_OS_MAC
#import <IOBluetooth/IOBluetooth.h>
#endif
#import "OKCharacteristic.h"
#import "OKPeripheral.h"
#import "OKUtils.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface OKService ()


/**
 * Discoveres Subscriber characteristics of this service
 */
@property (strong, nonatomic) id<RACSubscriber> discoverCharacteristicsSubscriber;

@end

@implementation OKService

/*----------------------------------------------------*/
#pragma mark - Getter/Setter -
/*----------------------------------------------------*/

- (NSString *)UUIDString
{
    return [self.cbService.UUID representativeString];
}

- (NSString *)description
{
    NSString *org = [super description];
    
    return [org stringByAppendingFormat:@" UUIDString: %@", self.UUIDString];
}

/*----------------------------------------------------*/
#pragma mark - Public Methods -
/*----------------------------------------------------*/

- (OKCharacteristic *)wrapperByCharacteristic:(CBCharacteristic *)aChar
{
    OKCharacteristic *wrapper = nil;
    for (OKCharacteristic *discovered in self.characteristics) {
        if (discovered.cbCharacteristic == aChar) {
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
    _discoverCharacteristicsCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(NSArray *input) {
        @strongify(self);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            if (self.cbService.peripheral.state != CBPeripheralStateConnected) {
                [subscriber sendError:[OKUtils discoverErrorWithCode:kOKUtilsMissingServiceErrorCode message:kOKUtilsMissingServiceErrorMessage]];
                return nil;
            }
            self.discoverCharacteristicsSubscriber = subscriber;
            [self.cbService.peripheral discoverCharacteristics:input forService:self.cbService];
            return [RACDisposable disposableWithBlock:^{
                self.discoverCharacteristicsSubscriber = nil;
            }];
        }];
    }];
    
    RAC(self, discoveringCharacteristics) = [self.discoverCharacteristicsCommand executing];
}

/*----------------------------------------------------*/
#pragma mark - Private Methods -
/*----------------------------------------------------*/

- (void)updateCharacteristicWrappers
{
    NSMutableArray *updatedCharacteristics = [NSMutableArray new];
    for (CBCharacteristic *characteristic in self.cbService.characteristics) {
        [updatedCharacteristics addObject:[[OKCharacteristic alloc] initWithCharacteristic:characteristic]];
    }
    _characteristics = updatedCharacteristics;
}

/*----------------------------------------------------*/
#pragma mark - Handler Methods -
/*----------------------------------------------------*/

- (void)handleDiscoveredCharacteristics:(NSArray *)aCharacteristics error:(NSError *)aError
{
    _discoveringCharacteristics = NO;
    [self updateCharacteristicWrappers];
#if OK_ENABLE_BLE_LOGGING != 0
    for (OKCharacteristic *aChar in self.characteristics) {
        OKLog(@"Characteristic discovered - %@", aChar.cbCharacteristic.UUID);
    }
#endif
    
    if (aError) {
        [self.discoverCharacteristicsSubscriber sendError:aError];
    }else {
        [self.discoverCharacteristicsSubscriber sendNext:self];
        [self.discoverCharacteristicsSubscriber sendCompleted];
    }
}


/*----------------------------------------------------*/
#pragma mark - Lifecycle -
/*----------------------------------------------------*/

- (instancetype)initWithService:(CBService *)aService
{
    if (self = [super init]) {
        _cbService = aService;
        [self initializeRAC];
    }
    return self;
}

@end
