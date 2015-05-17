//
//  DayCodeManager.h
//  Pixels
//
//  Created by Timo Kloss on 17/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DayCodeManager : NSObject

- (NSString *)todaysCode;
- (BOOL)isCodeValid:(NSString *)code;

@end
