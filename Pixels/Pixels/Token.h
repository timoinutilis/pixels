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
    TTypeSymCircle,
    TTypeSymText,
    TTypeSymEnd,
    TTypeSymGamepad,
    TTypeSymPrint,
    TTypeSymData,
    TTypeSymRead,
    TTypeSymRestore,
    TTypeSymDim,
    TTypeSymPaint,
    TTypeSymSprite,
    TTypeSymPalette,
    TTypeSymScroll,
    TTypeSymDef,
    TTypeSymOn,
    TTypeSymOff,
    TTypeSymWrite,
    TTypeSymClear,
    TTypeSymSound,
    TTypeSymLayer,
    TTypeSymGet,
    TTypeSymPut,
    TTypeSymPause,
    TTypeSymPersist,
    
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
    TTypeSymTap,
    TTypeSymMin,
    TTypeSymMax,
    
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
    
    // Reserved (not used yet)
    TType_reserved,
    TTypeSymInput,
    TTypeSymSub,
    TTypeSymCall,
    TTypeSymShared,
    TTypeSymSwap,
    TTypeSymUbound,
    TTypeSymScreen,
    TTypeSymPeek,
    TTypeSymPoke,
    TTypeSymRandomize,
    TTypeSymBank,
    TTypeSymDec,
    TTypeSymFont,
    TTypeSymInc,

    TType_count
};

@interface Token : NSObject

+ (NSString *)stringForType:(TType)type printable:(BOOL)printable;

@property TType type;
@property NSString *attrString;
@property float attrNumber;
@property NSUInteger position;

@end
