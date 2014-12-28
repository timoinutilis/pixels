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
@property (weak, nonatomic) IBOutlet UIToolbar *toolbarView;

@property UIToolbar *keyboardToolbar;

@end

@implementation EditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.project.name;
    
    UIBarButtonItem *runButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(onRunTapped:)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(onHelpTapped:)];
    self.navigationItem.rightBarButtonItems = @[runButton, helpButton];
    
    self.sourceCodeTextView.text = self.project.sourceCode ? self.project.sourceCode : @"";
    [self initKeyboardToolbar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)initKeyboardToolbar
{
    self.keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    self.keyboardToolbar.translucent = YES;
    
    NSArray *keys = @[@"=", @"<", @">", @"+", @"-", @"*", @"/", @"(", @")", @"\"", @"$"];
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSString *key in keys)
    {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:key style:UIBarButtonItemStylePlain target:self action:@selector(onSpecialKeyTapped:)];
        [buttons addObject:button];
    }
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [buttons addObject:space];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onKeyboardDoneTapped:)];
    [buttons addObject:doneButton];
    
    self.keyboardToolbar.items = buttons;
    self.sourceCodeTextView.inputAccessoryView = self.keyboardToolbar;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // set scrolling insets
    [self keyboardWillHide:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveProject];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize kbSize = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIEdgeInsets insets = UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, kbSize.height, 0);
    self.sourceCodeTextView.contentInset = insets;
    self.sourceCodeTextView.scrollIndicatorInsets = insets;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets insets = UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, self.toolbarView.frame.size.height, 0);
    self.sourceCodeTextView.contentInset = insets;
    self.sourceCodeTextView.scrollIndicatorInsets = insets;
}

- (void)saveProject
{
    if (self.project)
    {
        self.project.sourceCode = self.sourceCodeTextView.text;
    }
}

- (void)onSpecialKeyTapped:(UIBarButtonItem *)button
{
    [self.sourceCodeTextView insertText:button.title];
}

- (void)onKeyboardDoneTapped:(UIBarButtonItem *)button
{
    [self.sourceCodeTextView resignFirstResponder];
}

- (void)onRunTapped:(id)sender
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

- (void)onHelpTapped:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UIViewController *vc = (UIViewController *)[storyboard instantiateInitialViewController];
    vc.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:vc animated:YES completion:nil];
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
    vc.project = self.project;
    vc.nodes = nodes;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
