//
//  OKUtils.m
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#import "OKUtils.h"

/**
 * Error domain for Write errors
 */
NSString * const kOKUtilsWriteErrorDomain = @"OKUtilsWriteErrorDomain";

/**
 * Error domain for Scan errors
 */
NSString * const kOKUtilsScanErrorDomain = @"OKUtilsScanErrorDomain";

/**
 * Error domain for Read errors
 */
NSString * const kOKUtilsReadErrorDomain = @"OKUtilsReadErrorDomain";

/**
 * Error domain for Discover errors
 */
NSString * const kOKUtilsDiscoverErrorDomain = @"OKUtilsDiscoverErrorDomain";


/**
 * Global key for providing errors of OKBluetooth
 */
NSString * const kOKErrorMessageKey = @"msg";

/**
 * Error code for write operation
 * Service was not found on peripheral
 */
const NSInteger kOKUtilsMissingServiceErrorCode = 410;

/**
 * Error code for write operation
 * Characteristic was not found on peripheral
 */
const NSInteger kOKUtilsMissingCharacteristicErrorCode = 411;

/**
 * Error code for write operation
 * Characteristic data is nil
 */
const NSInteger kOKUtilsMissingCharacteristicDataErrorCode = 412;

/**
 * Error code for scan timeout
 */
const NSInteger kOKUtilsScanTimeoutErrorCode = 110;

/**
 * Error message for write operation
 * Service was not found on peripheral
 */
NSString * const kOKUtilsMissingServiceErrorMessage = @"Provided service UUID doesn't exist in provided pheripheral";

/**
 * Error message for write operation
 * Characteristic was not found on peripheral
 */
NSString * const kOKUtilsMissingCharacteristicErrorMessage = @"Provided characteristic doesn't exist in provided service";

/**
 * Error message for write operation
 * Characteristic data is nil
 */
NSString * const kOKUtilsMissingCharacteristicDataErrorMessage = @"Provided characteristic data is nil";

/**
 * Error message for scan timeout
 */
NSString * const kOKUtilsScanTimeoutErrorMessage = @"Scan peripherals timeOut, please retry later";

/**
 * Timeout of connection to peripheral
 */
const NSInteger kOKUtilsPeripheralConnectionTimeoutInterval = 30;

@implementation OKUtils

/*----------------------------------------------------*/
#pragma mark - Error Generators -
/*----------------------------------------------------*/

+ (NSError *)scanErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kOKUtilsScanErrorDomain
                               code:aCode
                           userInfo:@{kOKErrorMessageKey : aMsg}];
}

+ (NSError *)writeErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kOKUtilsWriteErrorDomain
                               code:aCode
                           userInfo:@{kOKErrorMessageKey : aMsg}];
}

+ (NSError *)readErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kOKUtilsReadErrorDomain
                               code:aCode
                           userInfo:@{kOKErrorMessageKey : aMsg}];
}

+ (NSError *)discoverErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kOKUtilsDiscoverErrorDomain
                               code:aCode
                           userInfo:@{kOKErrorMessageKey : aMsg}];
}

@end
