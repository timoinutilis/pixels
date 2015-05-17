//
//  DayCodeManager.m
//  Pixels
//
//  Created by Timo Kloss on 17/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "DayCodeManager.h"
#import "NSDate+Utils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation DayCodeManager

- (NSString *)todaysCode
{
    NSDate *date = [NSDate date].dateWithoutTime;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd";
    NSString *dateString = [formatter stringFromDate:date];
    NSString *code = [self encodeString:dateString];
    return code;
}

- (BOOL)isCodeValid:(NSString *)code
{
    return [code isEqualToString:[self todaysCode]];
}

- (NSString *)encodeString:(NSString *)input
{
    // Create pointer to the string as UTF8
    const char *ptr = [input UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
    
    uint16_t *firstWord = (uint16_t *)md5Buffer;

    return [NSString stringWithFormat:@"%04x", *firstWord];
}

@end
