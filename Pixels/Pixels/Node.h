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
- (void)prepareWithRunnable:(Runnable *)runnable pass:(PrePass)pass;
- (id)evaluateWithRunner:(Runner *)runner;
- (void)endOfLoopWithRunner:(Runner *)runner;
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
@property NSString *variable;
@property Node *startExpression;
@property Node *endExpression;
@property NSArray *commands;
@end

@interface LetNode : Node
@property NSString *identifier;
@property Node *expression;
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

@interface TextNode : Node
@property Node *valueExpression;
@property Node *xExpression;
@property Node *yExpression;
@property Node *alignExpression;
@end

@interface JoystickNode : Node
@property TType type;
@property Node *portExpression;
@end

@interface PointNode : Node
@property Node *xExpression;
@property Node *yExpression;
@end

@interface Maths0Node : Node
@property TType type;
@end

@interface Maths1Node : Node
@property TType type;
@property Node *xExpression;
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

@interface NumberNode : Node
@property float value;
@end

@interface StringNode : Node
@property NSString *value;
@end

@interface VariableNode : Node
@property NSString *identifier;
@end

@interface LabelNode : Node
@property NSString *identifier;
@end
