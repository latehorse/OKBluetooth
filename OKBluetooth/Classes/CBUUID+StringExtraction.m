//
//  CBUUID+StringExtraction.m
//  OKBluetooth
//
//  Created by yuhanle on 2018/7/27.
//

#import "CBUUID+StringExtraction.h"

@implementation CBUUID (StringExtraction)

/*----------------------------------------------------*/
#pragma mark - Helper Methods -
/*----------------------------------------------------*/

- (NSString *)representativeString
{
    NSData *data = [self data];
    
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++) {
        switch (currentByteIndex) {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
    }
    return outputString;
}

@end
