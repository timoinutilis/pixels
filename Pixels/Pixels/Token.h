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
    TTypeSymIf,
    TTypeSymThen,
    TTypeSymElse,
    TTypeSymGoto,
    TTypeSymGosub,
    TTypeSymReturn,
    TTypeSymPrint,
    TTypeSymFor,
    TTypeSymTo,
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
    
    // Functions
    TTypeSymUp,
    TTypeSymDown,
    TTypeSymLeft,
    TTypeSymRight,
    TTypeSymButton,
    TTypeSymPoint,
    TTypeSymRnd,
    
    // Constants
    TTypeSymTrue,
    TTypeSymFalse,
    
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
    TTypeSymOpOr,
    TTypeSymOpAnd,
    TTypeSymOpNot,
    
    TTypeSymColon,
    TTypeSymComma,
    TTypeSymEol,
    
    TType_count
};

@interface Token : NSObject

+ (NSString *)stringForType:(TType)type printable:(BOOL)printable;

@property TType type;
@property NSString *attrString;
@property float attrNumber;
@property NSUInteger line;

@end
