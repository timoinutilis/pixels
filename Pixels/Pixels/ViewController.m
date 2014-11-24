//
//  ViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "ViewController.h"
#import "Scanner.h"
#import "Parser.h"
#import "Token.h"
#import "CompilerException.h"
#import "Runner.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *sourceCodeTextView;
@property (weak, nonatomic) IBOutlet UITextView *consoleTextView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)runTapped:(id)sender
{
    [self compileText:self.sourceCodeTextView.text];
}

- (void)compileText:(NSString *)text
{
    NSMutableArray *lines = [NSMutableArray array];
    @try
    {
        Scanner *scanner = [[Scanner alloc] init];
        NSArray *tokens = [scanner tokenizeText:text.uppercaseString];
        for (Token *token in tokens)
        {
            [lines addObject:[NSString stringWithFormat:@"%@", token]];
        }
        
        Parser *parser = [[Parser alloc] init];
        NSArray *nodes = [parser parseTokens:tokens];
        
        Runner *runner = [[Runner alloc] initWithNodes:nodes];
        while (!runner.isFinished)
        {
            [runner runCommand];
        }
    }
    @catch (CompilerException *exception)
    {
        NSUInteger line = 0;
        if (exception.userInfo[@"line"])
        {
            line = [exception.userInfo[@"line"] intValue];
        }
        else if (exception.userInfo[@"token"])
        {
            Token *token = exception.userInfo[@"token"];
            line = token.line;
        }
        [lines addObject:[NSString stringWithFormat:@"Error in line %lu: %@", (unsigned long)line, exception.reason]];
    }

    self.consoleTextView.text = [lines componentsJoinedByString:@"\n"];
}

@end
