//
//  Node.h
//  Pixels
//
//  Created by Timo Kloss on 22/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Token.h"
#import "Runnable.h"

@class Runner;

@interface Node : NSObject

@property Token *token;

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass;
- (id)evaluateWithRunner:(Runner *)runner;
- (void)endOfLoopWithRunner:(Runner *)runner;
- (BOOL)returnsString;

@end

@interface NumberNode : Node
@property float value;
- (instancetype)initWithValue:(float)value;
@end

@interface StringNode : Node
@property NSString *value;
- (instancetype)initWithValue:(NSString *)value;
@end

@interface VariableNode : Node
@property NSString *identifier;
@property BOOL isString;
@property NSArray *indexExpressions;
- (NSArray *)indexesWithRunner:(Runner *)runner add:(int)addValue;
@end

@interface LabelNode : Node
@property NSString *identifier;
@end

@interface IfNode : Node
@property Node *condition;
@property NSArray *commands;
@property NSArray *elseCommands;
@end

@interface GotoNode : Node
@property NSString *label;
@end

@interface GosubNode : Node
@property NSString *label;
@end

@interface ReturnNode : Node
@end

@interface PrintNode : Node
@property Node *expression;
@end

@interface ForNextNode : Node
@property VariableNode *variable;
@property VariableNode *matchingVariable;
@property Node *startExpression;
@property Node *endExpression;
@property Node *stepExpression;
@property NSArray *commands;
@end

@interface LetNode : Node
@property VariableNode *variable;
@property Node *expression;
@end

@interface DimNode : Node
@property NSArray *variableNodes;
@end

@interface RepeatUntilNode : Node
@property Node *condition;
@property NSArray *commands;
@end

@interface WhileWendNode : Node
@property Node *condition;
@property NSArray *commands;
@end

@interface DoLoopNode : Node
@property NSArray *commands;
@end

@interface ExitNode : Node
@end

@interface WaitNode : Node
@property Node *time;
@end

@interface EndNode : Node
@end

@interface GamepadNode : Node
@property Node *playersExpression;
@end

@interface ColorNode : Node
@property Node *color;
@end

@interface ClsNode : Node
@property Node *color;
@end

@interface PlotNode : Node
@property Node *xExpression;
@property Node *yExpression;
@end

@interface LineNode : Node
@property Node *fromXExpression;
@property Node *fromYExpression;
@property Node *toXExpression;
@property Node *toYExpression;
@end

@interface BoxNode : Node
@property Node *fromXExpression;
@property Node *fromYExpression;
@property Node *toXExpression;
@property Node *toYExpression;
@property BOOL fill;
@end

@interface ScrollNode : Node
@property Node *fromXExpression;
@property Node *fromYExpression;
@property Node *toXExpression;
@property Node *toYExpression;
@property Node *deltaXExpression;
@property Node *deltaYExpression;
@end

@interface TextNode : Node
@property Node *valueExpression;
@property Node *xExpression;
@property Node *yExpression;
@property Node *alignExpression;
@end

@interface DefSpriteNode : Node
@property Node *imageExpression;
@property VariableNode *dataVariable;
@end

@interface SpritePaletteNode : Node
@property Node *nExpression;
@property Node *color1Expression;
@property Node *color2Expression;
@property Node *color3Expression;
@end

@interface SpriteNode : Node
@property Node *nExpression;
@property Node *xExpression;
@property Node *yExpression;
@property Node *imageExpression;
@end

@interface SpriteOffNode : Node
@property Node *nExpression;
@end

@interface DataNode : Node
@property NSArray *constants;
@end

@interface ReadNode : Node
@property NSArray *variables;
@end

@interface RestoreNode : Node
@property NSString *label;
@end

@interface DirectionPadNode : Node
@property TType type;
@property Node *portExpression;
@end

@interface ButtonNode : Node
@property Node *portExpression;
@property Node *buttonExpression;
@end

@interface PointNode : Node
@property Node *xExpression;
@property Node *yExpression;
@end

@interface TextWidthNode : Node
@property Node *valueExpression;
@end

@interface Maths0Node : Node
@property TType type;
@end

@interface Maths1Node : Node
@property TType type;
@property Node *xExpression;
@end

@interface LeftSNode : Node
@property Node *stringExpression;
@property Node *numberExpression;
@end

@interface RightSNode : Node
@property Node *stringExpression;
@property Node *numberExpression;
@end

@interface MidNode : Node
@property Node *stringExpression;
@property Node *positionExpression;
@property Node *numberExpression;
@end

@interface InstrNode : Node
@property Node *stringExpression;
@property Node *searchExpression;
@property Node *positionExpression;
@end

@interface ChrNode : Node
@property Node *asciiExpression;
@end

@interface AscNode : Node
@property Node *stringExpression;
@end

@interface LenNode : Node
@property Node *stringExpression;
@end

@interface ValNode : Node
@property Node *stringExpression;
@end

@interface StrNode : Node
@property Node *numberExpression;
@end

@interface HexNode : Node
@property Node *numberExpression;
@end

@interface Operator2Node : Node
@property TType type;
@property Node *leftExpression;
@property Node *rightExpression;
@end

@interface Operator1Node : Node
@property TType type;
@property Node *expression;
@end
