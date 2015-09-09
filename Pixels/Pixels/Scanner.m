//
//  Scanner.m
//  Pixels
//
//  Created by Timo Kloss on 19/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Scanner.h"
#import "Token.h"
#import "NSError+LowResCoder.h"

@interface Scanner ()
@property NSMutableDictionary *symbols;
@property NSArray *sortedSymbols;
@property NSCharacterSet *charSetNumbers;
@property NSCharacterSet *charSetLetters;
@property NSCharacterSet *charSetAlphaNum;
@end

@implementation Scanner

- (instancetype)init
{
    if (self = [super init])
    {
        [self initTables];
    }
    return self;
}

- (void)initTables
{
    self.symbols = [NSMutableDictionary dictionary];
    
    for (TType type = 0; type < TType_count; type++)
    {
        NSString *symbol = [Token stringForType:type printable:NO];
        if (symbol)
        {
            self.symbols[symbol] = @(type);
        }
    }
    
    self.sortedSymbols = [self.symbols.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        if (obj1.length > obj2.length) return NSOrderedAscending;
        if (obj1.length < obj2.length) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    self.charSetNumbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    self.charSetLetters = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ_"];
    self.charSetAlphaNum = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789"];
}

- (void)setError:(NSError *)error
{
    // don't overwrite existing error
    if (!_error)
    {
        _error = error;
    }
}

- (NSArray *)tokenizeText:(NSString *)text
{
    NSMutableArray *tokens = [NSMutableArray array];
    
    NSUInteger textPos = 0;
    NSUInteger len = text.length;
    NSUInteger tokenPosition = 0;
    while (textPos < len)
    {
        BOOL found = NO;
        
        tokenPosition = textPos;
        
        if (!found)
        {
            // check for line break
            
            unichar textCharacter = [text characterAtIndex:textPos];
            if (textCharacter == '\n')
            {
                Token *token = [[Token alloc] init];
                token.type = TTypeSymEol;
                token.position = tokenPosition;
                [tokens addObject:token];
                
                textPos++;
                found = YES;
            }
        }
        
        if (!found)
        {
            // whitespace
            
            unichar textCharacter = [text characterAtIndex:textPos];
            if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:textCharacter])
            {
                textPos++;
                found = YES;
            }
        }
        
        if (!found)
        {
            // search string
            
            if ([text characterAtIndex:textPos] == '"')
            {
                NSString *foundString = nil;
                for (NSUInteger stringPos = 1; textPos + stringPos < len; stringPos++)
                {
                    unichar textCharacter = [text characterAtIndex:textPos + stringPos];
                    if (textCharacter == '"')
                    {
                        NSRange range;
                        range.location = textPos + 1;
                        range.length = stringPos - 1;
                        foundString = [text substringWithRange:range];
                        textPos += stringPos + 1;
                        break;
                    }
                    else if (textCharacter == '\n')
                    {
                        self.error = [NSError programErrorWithCode:LRCErrorCodeTokenize reason:@"Expected end of string" position:textPos + stringPos];
                        return nil;
                    }
                }
                if (foundString)
                {
                    Token *token = [[Token alloc] init];
                    token.type = TTypeString;
                    token.attrString = foundString;
                    token.position = tokenPosition;
                    [tokens addObject:token];
                    found = YES;
                }
            }
        }
        
        if (!found)
        {
            // search number
            
            unichar textCharacter = [text characterAtIndex:textPos];
            if ([self.charSetNumbers characterIsMember:textCharacter])
            {
                float number = 0;
                int afterDot = 0;
                while (textPos < len)
                {
                    textCharacter = [text characterAtIndex:textPos];
                    if ([self.charSetNumbers characterIsMember:textCharacter])
                    {
                        int digit = (int)textCharacter - (int)'0';
                        if (afterDot == 0)
                        {
                            number *= 10;
                            number += digit;
                        }
                        else
                        {
                            number += (float)digit / afterDot;
                            afterDot *= 10;
                        }
                        textPos++;
                    }
                    else if (textCharacter == '.' && afterDot == 0)
                    {
                        afterDot = 10;
                        textPos++;
                    }
                    else
                    {
                        break;
                    }
                }
                Token *token = [[Token alloc] init];
                token.type = TTypeNumber;
                token.attrNumber = number;
                token.position = tokenPosition;
                [tokens addObject:token];
                found = YES;
            }
        }
        
        if (!found)
        {
            // search symbol
            
            NSString *foundSymbol = nil;
            for (NSString *symbol in self.sortedSymbols)
            {
                NSUInteger symbLen = symbol.length;
                BOOL symbolIsAlphaNum = [self.charSetAlphaNum characterIsMember:[symbol characterAtIndex:0]];
                for (NSUInteger symbPos = 0; symbPos <= symbLen && textPos + symbPos <= len; symbPos++)
                {
                    NSUInteger charPos = textPos + symbPos;
                    unichar textCharacter = (charPos < len) ? [text characterAtIndex:charPos] : '\n';
                    
                    if (symbPos < symbLen)
                    {
                        unichar symbCharacter = [symbol characterAtIndex:symbPos];
                        if (symbCharacter != textCharacter)
                        {
                            // not matching
                            break;
                        }
                    }
                    else if (symbolIsAlphaNum && [self.charSetAlphaNum characterIsMember:textCharacter])
                    {
                        // matching, but word is longer, so seems to be an identifier
                        break;
                    }
                    else
                    {
                        // symbol found!
                        foundSymbol = symbol;
                        textPos += symbLen;
                        break;
                    }
                }
                if (foundSymbol)
                {
                    break;
                }
            }
            if (foundSymbol)
            {
                TType type = [self.symbols[foundSymbol] intValue];
                if (type == TTypeSymRem)
                {
                    // REM comment, skip until end of line
                    while (textPos < len)
                    {
                        unichar textCharacter = [text characterAtIndex:textPos];
                        textPos++;
                        if (textCharacter == '\n')
                        {
                            break;
                        }
                    }
                }
                else if (type > TType_reserved)
                {
                    self.error = [NSError programErrorWithCode:LRCErrorCodeTokenize
                                                        reason:[NSString stringWithFormat:@"Reserved keyword %@", foundSymbol]
                                                      position:textPos];
                    return nil;
                }
                else
                {
                    Token *token = [[Token alloc] init];
                    token.type = type;
                    token.position = tokenPosition;
                    [tokens addObject:token];
                }
                found = YES;
            }
        }
        
        if (!found)
        {
            // search identifier
            
            unichar textCharacter = [text characterAtIndex:textPos];
            if ([self.charSetLetters characterIsMember:textCharacter])
            {
                NSUInteger startPos = textPos;
                while (textPos < len)
                {
                    textCharacter = [text characterAtIndex:textPos];
                    if ([self.charSetAlphaNum characterIsMember:textCharacter])
                    {
                        textPos++;
                    }
                    else
                    {
                        break;
                    }
                }
                NSRange range;
                range.location = startPos;
                range.length = textPos - startPos;
                
                Token *token = [[Token alloc] init];
                token.type = TTypeIdentifier;
                token.attrString = [text substringWithRange:range];
                token.position = tokenPosition;
                [tokens addObject:token];
                found = YES;
            }
        }
        
        if (!found)
        {
            unichar textCharacter = [text characterAtIndex:textPos];
            self.error = [NSError programErrorWithCode:LRCErrorCodeTokenize
                                                reason:[NSString stringWithFormat:@"Unexpected character '%c'", textCharacter]
                                              position:textPos];
            return nil;
        }
    }
    
    if (tokens.count > 0 && ((Token *)tokens.lastObject).type != TTypeSymEol)
    {
        Token *token = [[Token alloc] init];
        token.type = TTypeSymEol;
        token.position = len;
        [tokens addObject:token];
    }
    
    return tokens;
}

@end
