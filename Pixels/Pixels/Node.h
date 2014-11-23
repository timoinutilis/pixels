//
//  Node.h
//  Pixels
//
//  Created by Timo Kloss on 22/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Token.h"

@interface Node : NSObject
@end

@interface IfNode : Node
@property Node *condition;
@property Node *command;
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
