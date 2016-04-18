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
        
        case TTypeSymRem: return @"REM";
        case TTypeSymIf: return @"IF";
        case TTypeSymThen: return @"THEN";
        case TTypeSymElse: return @"ELSE";
        case TTypeSymGoto: return @"GOTO";
        case TTypeSymGosub: return @"GOSUB";
        case TTypeSymReturn: return @"RETURN";
        case TTypeSymFor: return @"FOR";
        case TTypeSymTo: return @"TO";
        case TTypeSymStep: return @"STEP";
        case TTypeSymNext: return @"NEXT";
        case TTypeSymLet: return @"LET";
        case TTypeSymRepeat: return @"REPEAT";
        case TTypeSymUntil: return @"UNTIL";
        case TTypeSymWhile: return @"WHILE";
        case TTypeSymWend: return @"WEND";
        case TTypeSymDo: return @"DO";
        case TTypeSymLoop: return @"LOOP";
        case TTypeSymExit: return @"EXIT";
        case TTypeSymWait: return @"WAIT";
        case TTypeSymScreen: return @"SCREEN";
        case TTypeSymColor: return @"COLOR";
        case TTypeSymCls: return @"CLS";
        case TTypeSymPlot: return @"PLOT";
        case TTypeSymLine: return @"LINE";
        case TTypeSymBox: return @"BOX";
        case TTypeSymBar: return @"BAR";
        case TTypeSymCircle: return @"CIRCLE";
        case TTypeSymText: return @"TEXT";
        case TTypeSymEnd: return @"END";
        case TTypeSymGamepad: return @"GAMEPAD";
        case TTypeSymPrint: return @"PRINT";
        case TTypeSymData: return @"DATA";
        case TTypeSymRead: return @"READ";
        case TTypeSymRestore: return @"RESTORE";
        case TTypeSymDim: return @"DIM";
        case TTypeSymPaint: return @"PAINT";
        case TTypeSymSprite: return @"SPRITE";
        case TTypeSymPalette: return @"PALETTE";
        case TTypeSymScroll: return @"SCROLL";
        case TTypeSymDef: return @"DEF";
        case TTypeSymOn: return @"ON";
        case TTypeSymOff: return @"OFF";
        case TTypeSymWrite: return @"WRITE";
        case TTypeSymClear: return @"CLEAR";
        case TTypeSymSound: return @"SOUND";
        case TTypeSymLayer: return @"LAYER";
        case TTypeSymGet: return @"GET";
        case TTypeSymPut: return @"PUT";
        case TTypeSymPause: return @"PAUSE";
        case TTypeSymPersist: return @"PERSIST";
        case TTypeSymSwap: return @"SWAP";
        case TTypeSymRandomize: return @"RANDOMIZE";
        case TTypeSymOpen: return @"OPEN";
        case TTypeSymClose: return @"CLOSE";
        case TTypeSymOffset: return @"OFFSET";
        case TTypeSymDisplay: return @"DISPLAY";
        case TTypeSymShared: return @"SHARED";
        case TTypeSymFont: return @"FONT";
        case TTypeSymScale: return @"SCALE";
        
        case TTypeSymUp: return @"UP";
        case TTypeSymDown: return @"DOWN";
        case TTypeSymLeft: return @"LEFT";
        case TTypeSymRight: return @"RIGHT";
        case TTypeSymButton: return @"BUTTON";
        case TTypeSymPoint: return @"POINT";
        case TTypeSymWidth: return @"WIDTH";
        case TTypeSymHit: return @"HIT";
        case TTypeSymLeftS: return @"LEFT$";
        case TTypeSymRightS: return @"RIGHT$";
        case TTypeSymMid: return @"MID$";
        case TTypeSymInstr: return @"INSTR";
        case TTypeSymChr: return @"CHR$";
        case TTypeSymAsc: return @"ASC";
        case TTypeSymLen: return @"LEN";
        case TTypeSymVal: return @"VAL";
        case TTypeSymStr: return @"STR$";
        case TTypeSymHex: return @"HEX$";
        case TTypeSymAbs: return @"ABS";
        case TTypeSymAtn: return @"ATN";
        case TTypeSymCos: return @"COS";
        case TTypeSymExp: return @"EXP";
        case TTypeSymInt: return @"INT";
        case TTypeSymLog: return @"LOG";
        case TTypeSymRnd: return @"RND";
        case TTypeSymSgn: return @"SGN";
        case TTypeSymSin: return @"SIN";
        case TTypeSymSqr: return @"SQR";
        case TTypeSymTan: return @"TAN";
        case TTypeSymTap: return @"TAP";
        case TTypeSymMin: return @"MIN";
        case TTypeSymMax: return @"MAX";
        case TTypeSymTimer: return @"TIMER";
        case TTypeSymTime: return @"TIME$";
        case TTypeSymDate: return @"DATE$";
        
        case TTypeSymTrue: return @"TRUE";
        case TTypeSymFalse: return @"FALSE";
        case TTypeSymPi: return @"PI";
        
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
        case TTypeSymOpAnd: return @"AND";
        case TTypeSymOpOr: return @"OR";
        case TTypeSymOpXor: return @"XOR";
        case TTypeSymOpNot: return @"NOT";
        case TTypeSymColon: return @":";
        case TTypeSymComma: return @",";
        case TTypeSymDollar: return @"$";
        case TTypeSymEol: return printable ? @"end of line" : nil;
        
        case TType_reserved: return nil;
        
        case TTypeSymInput: return @"INPUT";
        case TTypeSymSub: return @"SUB";
        case TTypeSymCall: return @"CALL";
        case TTypeSymUbound: return @"UBOUND";
        case TTypeSymPeek: return @"PEEK";
        case TTypeSymPoke: return @"POKE";
        case TTypeSymBank: return @"BANK";
        case TTypeSymTempo: return @"TEMPO";
        case TTypeSymTrace: return @"TRACE";
        case TTypeSymHeight: return @"HEIGHT";
        case TTypeSymTile: return @"TILE";
            
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
