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
- (NSArray *)indexesWithRunner:(Runner *)runner isDim:(BOOL)isDim;
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
@property NSString *label;
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
@property BOOL persist;
@end

@interface PersistNode : Node
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
@property BOOL tap;
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

@interface CircleNode : Node
@property Node *xExpression;
@property Node *yExpression;
@property Node *radiusXExpression;
@property Node *radiusYExpression;
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

@interface PaintNode : Node
@property Node *xExpression;
@property Node *yExpression;
@end

@interface PaletteNode : Node
@property BOOL clear;
@property Node *nExpression;
@property Node *valueExpression;
@end

@interface PaletteFuncNode : Node
@property Node *nExpression;
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

@interface WriteBaseNode : Node
@property NSMutableArray *strings;
- (void)addValue:(id)value;
- (void)writeDataLineWithRunner:(Runner *)runner;
@end

@interface WriteNode : WriteBaseNode
@property NSArray *valueExpressions;
@property BOOL clear;
@end

@interface WriteDimNode : WriteBaseNode
@property VariableNode *variable;
@property Node *columnsExpression;
@end

@interface OnXGotoNode : Node
@property TType xType;
@property NSString *label;
@end

@interface DefSoundNode : Node
@property Node *nExpression;
@property Node *waveExpression;
@property Node *pulseWidthExpression;
@property Node *maxTimeExpression;
@end

@interface DefSoundLineNode : Node
@property Node *nExpression;
@property Node *bendTimeExpression;
@property Node *pitchBendExpression;
@property Node *pulseBendExpression;
@end

@interface SoundNode : Node
@property Node *voiceExpression;
@property Node *pitchExpression;
@property Node *durationExpression;
@property Node *defExpression;
@end

@interface SoundOffNode : Node
@property Node *voiceExpression;
@end

@interface SoundEndNode : Node
@property Node *voiceExpression;
@end

@interface LayerNode : Node
@property Node *nExpression;
@end

@interface GetNode : Node
@property Node *fromXExpression;
@property Node *fromYExpression;
@property Node *toXExpression;
@property Node *toYExpression;
@end

@interface PutNode : Node
@property Node *xExpression;
@property Node *yExpression;
@property Node *srcXExpression;
@property Node *srcYExpression;
@property Node *srcWidthExpression;
@property Node *srcHeightExpression;
@property Node *transparencyExpression;
@end

@interface DirectionPadNode : Node
@property TType type;
@property Node *portExpression;
@end

@interface ButtonNode : Node
@property Node *portExpression;
@property Node *buttonExpression;
@property BOOL tap;
@end

@interface PointNode : Node
@property Node *xExpression;
@property Node *yExpression;
@end

@interface TextWidthNode : Node
@property Node *valueExpression;
@end

@interface SpriteValueNode : Node
@property unichar type;
@property Node *nExpression;
@end

@interface SpriteHitNode : Node
@property Node *nExpression;
@property Node *otherNExpression;
@property Node *lastNExpression;
@end

@interface Maths0Node : Node
@property TType type;
@end

@interface Maths1Node : Node
@property TType type;
@property Node *xExpression;
@end

@interface Maths2Node : Node
@property TType type;
@property Node *xExpression;
@property Node *yExpression;
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
