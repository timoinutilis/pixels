//
//  Token.m
//  Pixels
//
//  Created by Timo Kloss on 20/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "Token.h"

@implementation Token

+ (NSString *)stringForType:(TType)type printable:(BOOL)printable
{
    switch (type)
    {
        case TTypeString: return printable ? @"string" : nil;
        case TTypeNumber: return printable ? @"number" : nil;
        case TTypeIdentifier: return printable ? @"identifier" : nil;
        case TTypeSymIf: return @"IF";
        case TTypeSymThen: return @"THEN";
        case TTypeSymGoto: return @"GOTO";
        case TTypeSymGosub: return @"GOSUB";
        case TTypeSymReturn: return @"RETURN";
        case TTypeSymPrint: return @"PRINT";
        case TTypeSymFor: return @"FOR";
        case TTypeSymTo: return @"TO";
        case TTypeSymNext: return @"NEXT";
        case TTypeSymLet: return @"LET";
        case TTypeSymRepeat: return @"REPEAT";
        case TTypeSymUntil: return @"UNTIL";
        case TTypeSymWhile: return @"WHILE";
        case TTypeSymWend: return @"WEND";
        case TTypeSymDo: return @"DO";
        case TTypeSymLoop: return @"LOOP";
        case TTypeSymExit: return @"EXIT";
        case TTypeSymOpEq: return @"=";
        case TTypeSymOpGrEq: return @">=";
        case TTypeSymOpLeEq: return @"<=";
        case TTypeSymOpUneq: return @"<>";
        case TTypeSymOpGr: return @">";
        case TTypeSymOpLe: return @"<";
        case TTypeSymBracketOpen: return @"(";
        case TTypeSymBracketClose: return @")";
        case TTypeSymOpPlus: return @"+";
        case TTypeSymOpMinus: return @"-";
        case TTypeSymOpMul: return @"*";
        case TTypeSymOpDiv: return @"/";
        case TTypeSymOpMod: return @"MOD";
        case TTypeSymOpPow: return @"^";
        case TTypeSymOpOr: return @"OR";
        case TTypeSymOpAnd: return @"AND";
        case TTypeSymOpNot: return @"NOT";
        case TTypeSymColon: return @":";
        case TTypeSymEol: return printable ? @"end of line" : @"\n";
        case TType_count: return nil;
    }
    return nil;
}

- (NSString *)description
{
    if (self.type == TTypeString)
    {
        return [NSString stringWithFormat:@"string \"%@\"", self.attrString];
    }
    if (self.type == TTypeNumber)
    {
        return [NSString stringWithFormat:@"number %f", self.attrNumber];
    }
    if (self.type == TTypeIdentifier)
    {
        return [NSString stringWithFormat:@"identifier %@", self.attrString];
    }
    return [Token stringForType:self.type printable:YES];
}

@end
