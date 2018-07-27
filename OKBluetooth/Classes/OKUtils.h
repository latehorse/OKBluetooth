//
//  OKUtils.h
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/25.
//

#ifndef OK_BLE_SILENCE
#ifdef DEBUG
#define OK_ENABLE_BLE_LOGGING 1
#else
#define OK_ENABLE_BLE_LOGGING 0
#endif
#endif

#if OK_ENABLE_BLE_LOGGING != 0
#ifdef LOG_VERBOSE
#define OKLog(...) DDLogInfo(__VA_ARGS__)
#define OKLogError(...) DDLogError(__VA_ARGS__)
#else
#define OKLog(...) NSLog(__VA_ARGS__)
#define OKLogError(...) NSLog(__VA_ARGS__)
#endif
#else
#define OKLog(...) ((void)0)
#define OKLogError(...) ((void)0)
#endif

#import <Foundation/Foundation.h>

#pragma mark - Error Domains -

/**
 * Error domain for Write errors
 */
extern NSString * const kOKUtilsWriteErrorDomain;

/**
 * Error domain for Scan errors
 */
extern NSString * const kOKUtilsScanErrorDomain;

/**
 * Global error Message key
 */
extern NSString * const kOKErrorMessageKey;

#pragma mark - Error Codes -

/**
 * Error code for write operation
 * Service was not found on peripheral
 */
extern const NSInteger kOKUtilsMissingServiceErrorCode;

/**
 * Error code for write operation
 * Characteristic was not found on peripheral
 */
extern const NSInteger kOKUtilsMissingCharacteristicErrorCode;

/**
 * Error code for write operation
 * Characteristic data is nil
 */
extern const NSInteger kOKUtilsMissingCharacteristicDataErrorCode;

/**
 * Error code for scan timeout
 */
extern const NSInteger kOKUtilsScanTimeoutErrorCode;

#pragma mark - Error Messages -

/**
 * Error message for write operation
 * Service was not found on peripheral
 */
extern NSString * const kOKUtilsMissingServiceErrorMessage;

/**
 * Error message for write operation
 * Characteristic was not found on peripheral
 */
extern NSString * const kOKUtilsMissingCharacteristicErrorMessage;

/**
 * Error message for write operation
 * Characteristic data is nil
 */
extern NSString * const kOKUtilsMissingCharacteristicDataErrorMessage;

/**
 * Error message for scan timeout
 */
extern NSString * const kOKUtilsScanTimeoutErrorMessage;

@interface OKUtils : NSObject

/**
 * Error Generators - Scan

 @param aCode errCode
 @param aMsg errMessage
 @return NSError
 */
+ (NSError *)scanErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg;
/**
 * Error Generators - Write
 
 @param aCode errCode
 @param aMsg errMessage
 @return NSError
 */
+ (NSError *)writeErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg;
/**
 * Error Generators - Read
 
 @param aCode errCode
 @param aMsg errMessage
 @return NSError
 */
+ (NSError *)readErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg;
/**
 * Error Generators - Discover
 
 @param aCode errCode
 @param aMsg errMessage
 @return NSError
 */
+ (NSError *)discoverErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg;

@end
