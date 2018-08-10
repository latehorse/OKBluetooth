//
//  OKCharacteristic.m
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import "OKCharacteristic.h"

#import "CBUUID+StringExtraction.h"
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#elif TARGET_OS_MAC
#import <IOBluetooth/IOBluetooth.h>
#endif
#import <ReactiveObjC/ReactiveObjC.h>
#import "OKUtils.h"

@implementation OKWriteValueModel

- (instancetype)init {
    if (self = [super init]) {
        self.aInterval = 30.0;
        self.type = CBCharacteristicWriteWithoutResponse;
    }
    return self;
}

- (BOOL)hasMore {
    if (self.offset < self.data.length) {
        return YES;
    }
    return NO;
}

- (NSData *)subData {
    NSInteger totalLength = self.data.length;
    NSInteger remainLength = totalLength - self.offset;
    NSInteger rangLength = remainLength > 20 ? 20 : remainLength;
    return [self.data subdataWithRange:NSMakeRange(self.offset, rangLength)];
}

@end

@interface OKCharacteristic ()

/**
 * When write a long data, use.
 */
@property (nonatomic, strong) OKWriteValueModel *writeData;

/**
 * Peripheral's notifyValue subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull notifyValueSubscriber;

/**
 * Peripheral's notifyValue subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull notifySubscriber;

/**
 * Peripheral's writeValue subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull writeValueSubscriber;

/**
 * Peripheral's readValue subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull readValueSubscriber;

/**
 * Writes input data to characteristic
 * input @see OKWriteValueModel object representing bytes that needs to be written
 */
@property (nonatomic, strong, readonly) RACCommand *writeDataCommand;

/**
 * Peripheral's writeData subscriber
 */
@property (nonatomic, strong, readonly) id<RACSubscriber> _Nonnull writeDataSubscriber;

@end

@implementation OKCharacteristic

/*----------------------------------------------------*/
#pragma mark - Getter/Setter -
/*----------------------------------------------------*/

- (NSString *)UUIDString
{
    return [self.cbCharacteristic.UUID representativeString];
}

- (NSString *)description
{
    NSString *org = [super description];
    
    return [org stringByAppendingFormat:@" UUIDString: %@", self.UUIDString];
}

/*----------------------------------------------------*/
#pragma mark - Private Methods -
/*----------------------------------------------------*/

- (void)loopWirteValue {
    [[self.writeDataCommand execute:self.writeData] subscribeNext:^(id  _Nullable x) {
        [self.writeValueSubscriber sendNext:x];
    } error:^(NSError * _Nullable error) {
        [self.writeValueSubscriber sendError:error];
    } completed:^{
        [self.writeValueSubscriber sendCompleted];
    }];
}

/*----------------------------------------------------*/
#pragma mark - Handler Methods -
/*----------------------------------------------------*/

- (void)handleSetNotifiedWithError:(NSError *)anError
{
    OKLog(@"Characteristic - %@ notify changed with error - %@", self.cbCharacteristic.UUID, anError);
    
    if (anError) {
        [self.notifyValueSubscriber sendError:anError];
    }else {
        [self.notifyValueSubscriber sendNext:anError];
        [self.notifyValueSubscriber sendCompleted];
    }
}

- (void)handleReadValue:(NSData *)aValue error:(NSError *)anError
{
    OKLog(@"Characteristic - %@ value - %s error - %@", self.cbCharacteristic.UUID, [aValue bytes], anError);
    
    if (anError) {
        [self.readValueSubscriber sendError:anError];
    }else {
        [self.notifySubscriber sendNext:aValue];
        [self.readValueSubscriber sendNext:aValue];
        [self.readValueSubscriber sendCompleted];
    }
}

- (void)handleWrittenValueWithError:(NSError *)anError
{
    OKLog(@"Characteristic - %@ wrote with error - %@", self.cbCharacteristic.UUID, anError);
    
    if (anError) {
        [self.writeDataSubscriber sendError:anError];
    }else {
        if ([self.writeData hasMore]) {
            [self.writeDataSubscriber sendNext:self.writeData];
            
            // Continue send
            [self loopWirteValue];
        }else {
            [self.writeDataSubscriber sendNext:self.writeData];
            [self.writeDataSubscriber sendCompleted];
        }
    }
}

#pragma mark - InitializeRAC -

- (void)initializeRAC {
    @weakify(self);
    _notifyValueCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(NSNumber *input) {
        @strongify(self);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            if (self.cbCharacteristic.service.peripheral.state != CBPeripheralStateConnected) {
                [subscriber sendError:[OKUtils readErrorWithCode:kOKUtilsMissingCharacteristicErrorCode message:kOKUtilsMissingCharacteristicErrorMessage]];
                return nil;
            }
            _notifyValueSubscriber = subscriber;
            [self.cbCharacteristic.service.peripheral setNotifyValue:input.boolValue forCharacteristic:self.cbCharacteristic];
            return [RACDisposable disposableWithBlock:^{
                _notifyValueSubscriber = nil;
            }];
        }];
    }];
    
    _writeDataCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(OKWriteValueModel *input) {
        @strongify(self);
        if (input.data.length == 0) {
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                [subscriber sendError:[OKUtils writeErrorWithCode:kOKUtilsMissingCharacteristicDataErrorCode message:kOKUtilsMissingCharacteristicDataErrorMessage]];
                return [RACDisposable disposableWithBlock:^{
                    
                }];
            }];
        }
        
        if (input.type == CBCharacteristicWriteWithoutResponse) {
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                if (self.cbCharacteristic.service.peripheral.state != CBPeripheralStateConnected) {
                    [subscriber sendError:[OKUtils writeErrorWithCode:kOKUtilsMissingCharacteristicErrorCode message:kOKUtilsMissingCharacteristicErrorMessage]];
                    return nil;
                }
                [self.cbCharacteristic.service.peripheral writeValue:input.subData forCharacteristic:self.cbCharacteristic type:input.type];
                [subscriber sendCompleted];
                return [RACDisposable disposableWithBlock:^{
                    
                }];
            }];
        }
        
        RACSubject *timeoutSubject = [RACSubject subject];
        RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            _writeDataSubscriber = subscriber;
            [self.cbCharacteristic.service.peripheral writeValue:input.subData forCharacteristic:self.cbCharacteristic type:input.type];
            return [RACDisposable disposableWithBlock:^{
                [timeoutSubject sendCompleted];
                _writeDataSubscriber = nil;
            }];
        }];
        
        // Subscribe command errors, then we can know the timeout
        [[timeoutSubject timeout:input.aInterval onScheduler:[RACScheduler mainThreadScheduler]] subscribeError:^(NSError * _Nullable error) {
            if (error.code == 1) {
                [self.writeDataSubscriber sendError:[OKUtils scanErrorWithCode:kOKUtilsWriteErrorDomain message:kOKUtilsWriteErrorDomain]];
            }
        }];
        
        return signal;
    }];
    
    _writeValueCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(OKWriteValueModel *input) {
        @strongify(self);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            _writeValueSubscriber = subscriber;
            _writeData = input;
            
            [self loopWirteValue];
            return [RACDisposable disposableWithBlock:^{
                _writeValueSubscriber = nil;
            }];
        }];
    }];
    
    _readValueCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        @strongify(self);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            if (self.cbCharacteristic.service.peripheral.state != CBPeripheralStateConnected) {
                [subscriber sendError:[OKUtils readErrorWithCode:kOKUtilsMissingCharacteristicErrorCode message:kOKUtilsMissingCharacteristicErrorMessage]];
                return nil;
            }
            _readValueSubscriber = subscriber;
            [self.cbCharacteristic.service.peripheral readValueForCharacteristic:self.cbCharacteristic];
            return [RACDisposable disposableWithBlock:^{
                _readValueSubscriber = nil;
            }];
        }];
    }];
    
    _notifyValueSignal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        _notifySubscriber = subscriber;
        return [RACDisposable disposableWithBlock:^{
            _notifyValueSignal = nil;
        }];
    }];
}

/*----------------------------------------------------*/
#pragma mark - Lifecycle -
/*----------------------------------------------------*/

- (instancetype)initWithCharacteristic:(CBCharacteristic *)aCharacteristic
{
    if (self = [super init]) {
        _cbCharacteristic = aCharacteristic;
        [self initializeRAC];
    }
    return self;
}

@end
