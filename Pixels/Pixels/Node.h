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

@property (nonatomic) Token *token;

- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass;
- (id)evaluateWithRunner:(Runner *)runner;
- (void)endOfLoopWithRunner:(Runner *)runner;
- (BOOL)returnsString;

@end

@interface NumberNode : Node
@property (nonatomic) float value;
- (instancetype)initWithValue:(float)value;
@end

@interface StringNode : Node
@property (nonatomic) NSString *value;
- (instancetype)initWithValue:(NSString *)value;
@end

@interface VariableNode : Node
@property (nonatomic) NSString *identifier;
@property (nonatomic) BOOL isString;
@property (nonatomic) NSArray *indexExpressions;
- (NSArray *)indexesWithRunner:(Runner *)runner isDim:(BOOL)isDim;
@end

@interface LabelNode : Node
@property (nonatomic) NSString *identifier;
@end

@interface IfNode : Node
@property (nonatomic) Node *condition;
@property (nonatomic) NSArray *commands;
@property (nonatomic) NSArray *elseCommands;
@end

@interface GotoNode : Node
@property (nonatomic) NSString *label;
@end

@interface GosubNode : Node
@property (nonatomic) NSString *label;
@end

@interface ReturnNode : Node
@property (nonatomic) NSString *label;
@end

@interface PrintNode : Node
@property (nonatomic) Node *expression;
@end

@interface ForNextNode : Node
@property (nonatomic) VariableNode *variable;
@property (nonatomic) VariableNode *matchingVariable;
@property (nonatomic) Node *startExpression;
@property (nonatomic) Node *endExpression;
@property (nonatomic) Node *stepExpression;
@property (nonatomic) NSArray *commands;
@end

@interface LetNode : Node
@property (nonatomic) VariableNode *variable;
@property (nonatomic) Node *expression;
@end

@interface DimNode : Node
@property (nonatomic) NSArray *variableNodes;
@property (nonatomic) BOOL persist;
@end

@interface PersistNode : Node
@property (nonatomic) NSArray *variableNodes;
@end

@interface SwapNode : Node
@property (nonatomic) VariableNode *variable1;
@property (nonatomic) VariableNode *variable2;
@end

@interface RandomizeNode : Node
@property (nonatomic) Node *expression;
@end

@interface RepeatUntilNode : Node
@property (nonatomic) Node *condition;
@property (nonatomic) NSArray *commands;
@end

@interface WhileWendNode : Node
@property (nonatomic) Node *condition;
@property (nonatomic) NSArray *commands;
@end

@interface DoLoopNode : Node
@property (nonatomic) NSArray *commands;
@end

@interface ExitNode : Node
@end

@interface WaitNode : Node
@property (nonatomic) Node *time;
@property (nonatomic) BOOL tap;
@end

@interface EndNode : Node
@end

@interface GamepadNode : Node
@property (nonatomic) Node *playersExpression;
@end

@interface DisplayNode : Node
@property (nonatomic) Node *modeExpression;
@property (nonatomic) BOOL sharedPalette;
@end

@interface ScreenOpenNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *widthExpression;
@property (nonatomic) Node *heightExpression;
@property (nonatomic) Node *renderModeExpression;
@end

@interface ScreenCloseNode : Node
@property (nonatomic) Node *nExpression;
@end

@interface ScreenOffsetNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@end

@interface ScreenDisplayNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@property (nonatomic) Node *widthExpression;
@property (nonatomic) Node *heightExpression;
@end

@interface ScreenOnOffNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) BOOL visible;
@end

@interface ScreenNode : Node
@property (nonatomic) Node *nExpression;
@end

@interface ColorNode : Node
@property (nonatomic) Node *color;
@property (nonatomic) Node *bgColor;
@property (nonatomic) Node *borderColor;
@end

@interface ClsNode : Node
@property (nonatomic) Node *color;
@end

@interface PlotNode : Node
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@end

@interface LineNode : Node
@property (nonatomic) Node *fromXExpression;
@property (nonatomic) Node *fromYExpression;
@property (nonatomic) Node *toXExpression;
@property (nonatomic) Node *toYExpression;
@end

@interface BoxNode : Node
@property (nonatomic) Node *fromXExpression;
@property (nonatomic) Node *fromYExpression;
@property (nonatomic) Node *toXExpression;
@property (nonatomic) Node *toYExpression;
@property (nonatomic) BOOL fill;
@end

@interface CircleNode : Node
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@property (nonatomic) Node *radiusXExpression;
@property (nonatomic) Node *radiusYExpression;
@property (nonatomic) BOOL fill;
@end

@interface ScrollNode : Node
@property (nonatomic) Node *fromXExpression;
@property (nonatomic) Node *fromYExpression;
@property (nonatomic) Node *toXExpression;
@property (nonatomic) Node *toYExpression;
@property (nonatomic) Node *deltaXExpression;
@property (nonatomic) Node *deltaYExpression;
@property (nonatomic) BOOL refill;
@end

@interface TextNode : Node
@property (nonatomic) Node *valueExpression;
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@property (nonatomic) Node *alignExpression;
@property (nonatomic) Node *outlineExpression;
@end

@interface FontNode : Node
@property (nonatomic) Node *fontExpression;
@end

@interface PaintNode : Node
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@end

@interface PaletteNode : Node
@property (nonatomic) BOOL clear;
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *valueExpression;
@end

@interface PaletteFuncNode : Node
@property (nonatomic) Node *nExpression;
@end

@interface DefSpriteNode : Node
@property (nonatomic) Node *imageExpression;
@property (nonatomic) VariableNode *dataVariable;
@property (nonatomic) Node *color1Expression;
@property (nonatomic) Node *color2Expression;
@property (nonatomic) Node *color3Expression;
@end

@interface SpritePaletteNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *color1Expression;
@property (nonatomic) Node *color2Expression;
@property (nonatomic) Node *color3Expression;
@end

@interface SpriteScaleNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@end

@interface SpriteNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@property (nonatomic) Node *imageExpression;
@end

@interface SpriteOffNode : Node
@property (nonatomic) Node *nExpression;
@end

@interface SpriteScreenNode : Node
@property (nonatomic) Node *screenExpression;
@property (nonatomic) Node *spriteFromExpression;
@property (nonatomic) Node *spriteToExpression;
@end

@interface DataNode : Node
@property (nonatomic) NSArray *constants;
@end

@interface ReadNode : Node
@property (nonatomic) NSArray *variables;
@end

@interface RestoreNode : Node
@property (nonatomic) NSString *label;
@end

@interface WriteBaseNode : Node
@property (nonatomic) NSMutableArray *strings;
- (void)addValue:(id)value;
- (void)writeDataLineWithRunner:(Runner *)runner;
@end

@interface WriteNode : WriteBaseNode
@property (nonatomic) NSArray *valueExpressions;
@property (nonatomic) BOOL clear;
@end

@interface WriteDimNode : WriteBaseNode
@property (nonatomic) VariableNode *variable;
@property (nonatomic) Node *columnsExpression;
@end

@interface OnXGotoNode : Node
@property (nonatomic) TType xType;
@property (nonatomic) NSString *label;
@end

@interface DefSoundNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *waveExpression;
@property (nonatomic) Node *pulseWidthExpression;
@property (nonatomic) Node *maxTimeExpression;
@end

@interface DefSoundLineNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *bendTimeExpression;
@property (nonatomic) Node *pitchBendExpression;
@property (nonatomic) Node *pulseBendExpression;
@end

@interface SoundNode : Node
@property (nonatomic) Node *voiceExpression;
@property (nonatomic) Node *pitchExpression;
@property (nonatomic) Node *durationExpression;
@property (nonatomic) Node *defExpression;
@end

@interface SoundOffNode : Node
@property (nonatomic) Node *voiceExpression;
@end

@interface SoundEndNode : Node
@property (nonatomic) Node *voiceExpression;
@end

@interface GetNode : Node
@property (nonatomic) Node *fromXExpression;
@property (nonatomic) Node *fromYExpression;
@property (nonatomic) Node *toXExpression;
@property (nonatomic) Node *toYExpression;
@end

@interface PutNode : Node
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@property (nonatomic) Node *srcXExpression;
@property (nonatomic) Node *srcYExpression;
@property (nonatomic) Node *srcWidthExpression;
@property (nonatomic) Node *srcHeightExpression;
@property (nonatomic) Node *transparencyExpression;
@end

@interface GetBlockNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *fromXExpression;
@property (nonatomic) Node *fromYExpression;
@property (nonatomic) Node *toXExpression;
@property (nonatomic) Node *toYExpression;
@end

@interface PutBlockNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@property (nonatomic) Node *maskExpression;
@end

@interface LeftSCommandNode : Node
@property (nonatomic) VariableNode *stringVariable;
@property (nonatomic) Node *numberExpression;
@property (nonatomic) Node *srcStringExpression;
@end

@interface RightSCommandNode : Node
@property (nonatomic) VariableNode *stringVariable;
@property (nonatomic) Node *numberExpression;
@property (nonatomic) Node *srcStringExpression;
@end

@interface MidCommandNode : Node
@property (nonatomic) VariableNode *stringVariable;
@property (nonatomic) Node *positionExpression;
@property (nonatomic) Node *numberExpression;
@property (nonatomic) Node *srcStringExpression;
@end

@interface DirectionPadNode : Node
@property (nonatomic) TType type;
@property (nonatomic) Node *portExpression;
@end

@interface ButtonNode : Node
@property (nonatomic) Node *portExpression;
@property (nonatomic) Node *buttonExpression;
@property (nonatomic) BOOL tap;
@end

@interface PointNode : Node
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@end

@interface TextWidthNode : Node
@property (nonatomic) Node *valueExpression;
@end

@interface SpriteValueNode : Node
@property (nonatomic) unichar type;
@property (nonatomic) Node *nExpression;
@end

@interface SpriteHitNode : Node
@property (nonatomic) Node *nExpression;
@property (nonatomic) Node *otherNExpression;
@property (nonatomic) Node *lastNExpression;
@end

@interface ScreenHitNode : Node
@property (nonatomic) Node *screenExpression;
@property (nonatomic) Node *spriteExpression;
@end

@interface Maths0Node : Node
@property (nonatomic) TType type;
@end

@interface Maths1Node : Node
@property (nonatomic) TType type;
@property (nonatomic) Node *xExpression;
@end

@interface Maths2Node : Node
@property (nonatomic) TType type;
@property (nonatomic) Node *xExpression;
@property (nonatomic) Node *yExpression;
@end

@interface String0Node : Node
@property (nonatomic) TType type;
@end

@interface LeftSNode : Node
@property (nonatomic) Node *stringExpression;
@property (nonatomic) Node *numberExpression;
@end

@interface RightSNode : Node
@property (nonatomic) Node *stringExpression;
@property (nonatomic) Node *numberExpression;
@end

@interface MidNode : Node
@property (nonatomic) Node *stringExpression;
@property (nonatomic) Node *positionExpression;
@property (nonatomic) Node *numberExpression;
@end

@interface InstrNode : Node
@property (nonatomic) Node *stringExpression;
@property (nonatomic) Node *searchExpression;
@property (nonatomic) Node *positionExpression;
@end

@interface ChrNode : Node
@property (nonatomic) Node *asciiExpression;
@end

@interface AscNode : Node
@property (nonatomic) Node *stringExpression;
@end

@interface LenNode : Node
@property (nonatomic) Node *stringExpression;
@end

@interface ValNode : Node
@property (nonatomic) Node *stringExpression;
@end

@interface StrNode : Node
@property (nonatomic) Node *numberExpression;
@end

@interface HexNode : Node
@property (nonatomic) Node *numberExpression;
@end

@interface Operator2Node : Node
@property (nonatomic) TType type;
@property (nonatomic) Node *leftExpression;
@property (nonatomic) Node *rightExpression;
@end

@interface Operator1Node : Node
@property (nonatomic) TType type;
@property (nonatomic) Node *expression;
@end
