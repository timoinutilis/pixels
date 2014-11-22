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
@property TType type;
@end

@interface IfNode : Node
@property Node *condition;
@property NSArray *commands;
@end

@interface GotoNode : Node
@property Node *label;
@end

@interface GosubNode : Node
@property Node *label;
@end

@interface LetNode : Node
@property Node *identifier;
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

@interface Operator2Node : Node
@property Node *leftExpression;
@property Node *rightExpression;
@end

@interface Operator1Node : Node
@property Node *expression;
@end
