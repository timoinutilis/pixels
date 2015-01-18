//
//  NSString+Utils.m
//  Pixels
//
//  Created by Timo Kloss on 18/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

- (NSString *)substringWithLineAtIndex:(NSUInteger)index
{
    NSUInteger lineStart = 0;
    NSUInteger lineEnd = self.length;
    
    NSRange lineStartRange = [self rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, index)];
    NSRange lineEndRange = [self rangeOfString:@"\n" options:0 range:NSMakeRange(index, self.length - index)];
    
    if (lineStartRange.location != NSNotFound)
    {
        lineStart = lineStartRange.location + 1;
    }
    if (lineEndRange.location != NSNotFound)
    {
        lineEnd = lineEndRange.location;
    }
    
    return [self substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
}

@end
