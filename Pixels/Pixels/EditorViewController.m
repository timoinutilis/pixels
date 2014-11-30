//
//  ViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "EditorViewController.h"
#import "Scanner.h"
#import "Parser.h"
#import "Token.h"
#import "CompilerException.h"
#import "Runner.h"
#import "ModelManager.h"
#import "RunnerViewController.h"

@interface EditorViewController ()

@property (weak, nonatomic) IBOutlet UITextView *sourceCodeTextView;

@end

@implementation EditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.project.name;
    self.sourceCodeTextView.text = self.project.sourceCode ? self.project.sourceCode : @"";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveProject];
}

- (void)saveProject
{
    if (self.project)
    {
        self.project.sourceCode = self.sourceCodeTextView.text;
    }
}

- (IBAction)runTapped:(id)sender
{
    [self saveProject];
    [self compileText:self.sourceCodeTextView.text];
}

- (IBAction)onDeleteTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you really want to delete this project?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        [[ModelManager sharedManager] deleteProject:self.project];
        self.project = nil;
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onDuplicateTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you want to make a copy of this project?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Duplicate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self saveProject];
        [[ModelManager sharedManager] duplicateProject:self.project];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onRenameTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Enter new project name" message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.project.name;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        self.project.name = ((UITextField *)alert.textFields[0]).text;
        self.navigationItem.title = self.project.name;
        [self saveProject];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onActionTapped:(id)sender
{
}

- (void)compileText:(NSString *)text
{
    @try
    {
        Scanner *scanner = [[Scanner alloc] init];
        NSArray *tokens = [scanner tokenizeText:text.uppercaseString];
        
        Parser *parser = [[Parser alloc] init];
        NSArray *nodes = [parser parseTokens:tokens];
        
        [self runWithNodes:nodes];
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
        NSString *message = [NSString stringWithFormat:@"Error in line %lu: %@", (unsigned long)line, exception.reason];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)runWithNodes:(NSArray *)nodes
{
    RunnerViewController *vc = (RunnerViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"Runner"];
    vc.nodes = nodes;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
