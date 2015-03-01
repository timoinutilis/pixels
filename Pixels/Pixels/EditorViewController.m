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
#import "Runnable.h"
#import "ProgramException.h"
#import "Runner.h"
#import "ModelManager.h"
#import "RunnerViewController.h"
#import "HelpTextViewController.h"
#import "ActivityItemSource.h"
#import "PublishActivity.h"
#import "NSString+Utils.h"
#import "EditorTextView.h"

@interface EditorViewController ()

@property (weak, nonatomic) IBOutlet EditorTextView *sourceCodeTextView;

@end

@implementation EditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.project.name;
    
    UIBarButtonItem *runButton = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStyleDone target:self action:@selector(onRunTapped:)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(onHelpTapped:)];
    self.navigationItem.rightBarButtonItems = @[runButton, helpButton];
    
    self.sourceCodeTextView.text = self.project.sourceCode ? self.project.sourceCode : @"";
    if (self.project.isDefault.boolValue)
    {
        self.sourceCodeTextView.editable = NO;
        self.sourceCodeTextView.selectable = NO;
        
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSourceCodeTapped:)];
        [self.sourceCodeTextView addGestureRecognizer:recognizer];
    }
    self.sourceCodeTextView.layoutManager.allowsNonContiguousLayout = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveData:) name:ModelManagerWillSaveDataNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerWillSaveDataNotification object:nil];
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
    UIEdgeInsets insets = UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, self.navigationController.toolbar.frame.size.height, 0);
    self.sourceCodeTextView.contentInset = insets;
    self.sourceCodeTextView.scrollIndicatorInsets = insets;
}

- (void)willSaveData:(NSNotification *)notification
{
    [self saveProject];
}

- (void)saveProject
{
    if (self.project)
    {
        self.project.sourceCode = self.sourceCodeTextView.text;
    }
}

- (void)onSourceCodeTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example programs cannot be edited" message:@"Do you want to make an editable copy of this program?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Duplicate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[ModelManager sharedManager] duplicateProject:self.project];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    alert.view.tintColor = self.view.tintColor;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onRunTapped:(id)sender
{
    [self runProgram];
}

- (IBAction)onDeleteTapped:(id)sender
{
    if (self.project.isDefault.boolValue)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example programs cannot be deleted." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (self.sourceCodeTextView.text.length == 0)
    {
        [self deleteProject];
    }
    else
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you really want to delete this program?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [self deleteProject];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)deleteProject
{
    [[ModelManager sharedManager] deleteProject:self.project];
    self.project = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onDuplicateTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you want to make a copy of this program?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Duplicate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self saveProject];
        [[ModelManager sharedManager] duplicateProject:self.project];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    alert.view.tintColor = self.view.tintColor;
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onRenameTapped:(id)sender
{
    if (self.project.isDefault.boolValue)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example programs cannot renamed." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Enter new program name" message:nil preferredStyle:UIAlertControllerStyleAlert];

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
        
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)onActionTapped:(id)sender
{
    if (self.sourceCodeTextView.text.length == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"This program is empty. Write something!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self saveProject];
        
        ActivityItemSource *item = [[ActivityItemSource alloc] init];
        item.project = self.project;
        
        PublishActivity *publishActivity = [[PublishActivity alloc] init];
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[item] applicationActivities:@[publishActivity]];
        
        activityVC.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

- (void)onHelpTapped:(id)sender
{
    [HelpTextViewController showHelpWithParent:self];
}

#pragma mark - Compile and run

- (void)runProgram
{
    NSString *sourceCode = self.sourceCodeTextView.text;
    NSString *transferSourceCode = [EditorTextView transferText];
    
    NSArray *transferDataNodes;
    
    if (transferSourceCode.length > 0)
    {
        @try
        {
            Runnable *runnable = [self compileSourceCode:transferSourceCode];
            transferDataNodes = runnable.dataNodes;
        }
        @catch (NSException *exception)
        {
            // ignore
        }
    }
    
    @try
    {
        Runnable *runnable = [self compileSourceCode:sourceCode];
        if (runnable)
        {
            runnable.transferDataNodes = transferDataNodes;
            [self run:runnable];
        }
    }
    @catch (ProgramException *exception)
    {
        NSUInteger errorPosition = exception.position;
        NSString *line = [sourceCode substringWithLineAtIndex:errorPosition];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:exception.reason message:line preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Go to Error" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSRange range = NSMakeRange(errorPosition, 0);
            self.sourceCodeTextView.selectedRange = range;
            [self.sourceCodeTextView becomeFirstResponder];
        }]];
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (Runnable *)compileSourceCode:(NSString *)sourceCode
{
    Scanner *scanner = [[Scanner alloc] init];
    NSArray *tokens = [scanner tokenizeText:sourceCode.uppercaseString];
    
    if (tokens.count > 0)
    {
        Parser *parser = [[Parser alloc] init];
        NSArray *nodes = [parser parseTokens:tokens];
        
        if (nodes.count > 0)
        {
            Runnable *runnable = [[Runnable alloc] initWithNodes:nodes];
            [runnable prepare];
            
            return runnable;
        }
    }
    return nil;
}

- (void)run:(Runnable *)runnable
{
    RunnerViewController *vc = (RunnerViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"Runner"];
    vc.project = self.project;
    vc.runnable = runnable;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
