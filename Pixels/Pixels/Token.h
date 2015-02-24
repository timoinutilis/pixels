//
//  Token.h
//  Pixels
//
//  Created by Timo Kloss on 20/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TType) {
    TTypeString,
    TTypeNumber,
    TTypeIdentifier,
    
    // Commands
    TTypeSymRem,
    TTypeSymIf,
    TTypeSymThen,
    TTypeSymElse,
    TTypeSymGoto,
    TTypeSymGosub,
    TTypeSymReturn,
    TTypeSymFor,
    TTypeSymTo,
    TTypeSymStep,
    TTypeSymNext,
    TTypeSymLet,
    TTypeSymRepeat,
    TTypeSymUntil,
    TTypeSymWhile,
    TTypeSymWend,
    TTypeSymDo,
    TTypeSymLoop,
    TTypeSymExit,
    TTypeSymWait,
    TTypeSymColor,
    TTypeSymCls,
    TTypeSymPlot,
    TTypeSymLine,
    TTypeSymBox,
    TTypeSymBar,
    TTypeSymText,
    TTypeSymEnd,
    TTypeSymGamepad,
    TTypeSymPrint,
    TTypeSymInput,
    TTypeSymData,
    TTypeSymRead,
    TTypeSymRestore,
    TTypeSymDim,
    TTypeSymPaint,
    TTypeSymCircle,
    TTypeSymSprite,
    TTypeSymPalette,
    TTypeSymScroll,
    TTypeSymDef,
    TTypeSymOff,
    TTypeSymWrite,
    TTypeSymClear,
    
    // Functions
    TTypeSymUp,
    TTypeSymDown,
    TTypeSymLeft,
    TTypeSymRight,
    TTypeSymButton,
    TTypeSymPoint,
    TTypeSymWidth,
    TTypeSymHit,
    TTypeSymLeftS,
    TTypeSymRightS,
    TTypeSymMid,
    TTypeSymInstr,
    TTypeSymChr,
    TTypeSymAsc,
    TTypeSymLen,
    TTypeSymVal,
    TTypeSymStr,
    TTypeSymHex,
    TTypeSymAbs,
    TTypeSymAtn,
    TTypeSymCos,
    TTypeSymExp,
    TTypeSymInt,
    TTypeSymLog,
    TTypeSymRnd,
    TTypeSymSgn,
    TTypeSymSin,
    TTypeSymSqr,
    TTypeSymTan,
    
    // Constants
    TTypeSymTrue,
    TTypeSymFalse,
    TTypeSymPi,
    
    // Operators
    TTypeSymOpEq,
    TTypeSymOpGrEq,
    TTypeSymOpLeEq,
    TTypeSymOpUneq,
    TTypeSymOpGr,
    TTypeSymOpLe,
    TTypeSymBracketOpen,
    TTypeSymBracketClose,
    TTypeSymOpPlus,
    TTypeSymOpMinus,
    TTypeSymOpMul,
    TTypeSymOpDiv,
    TTypeSymOpMod,
    TTypeSymOpPow,
    TTypeSymOpAnd,
    TTypeSymOpOr,
    TTypeSymOpXor,
    TTypeSymOpNot,
    
    TTypeSymColon,
    TTypeSymComma,
    TTypeSymDollar,
    TTypeSymEol,
    
    TType_count
};

@interface Token : NSObject

+ (NSString *)stringForType:(TType)type printable:(BOOL)printable;

@property TType type;
@property NSString *attrString;
@property float attrNumber;
@property NSUInteger position;

@end
