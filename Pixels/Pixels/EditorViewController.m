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
#import "AppController.h"
#import "CoachMarkView.h"
#import "AppStyle.h"

int const EditorDemoMaxLines = 24;
NSString *const CoachMarkIDStart = @"CoachMarkIDStart";
NSString *const CoachMarkIDShare = @"CoachMarkIDShare";
NSString *const CoachMarkIDHelp = @"CoachMarkIDHelp";


@interface EditorViewController ()

@property (weak, nonatomic) IBOutlet EditorTextView *sourceCodeTextView;
@property BOOL examplesDontSaveWarningShowed;
@property BOOL wasEditedSinceOpened;
@property BOOL wasEditedSinceLastRun;

@end

@implementation EditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sourceCodeTextView.backgroundColor = [AppStyle darkColor];
    self.sourceCodeTextView.textColor = [AppStyle tintColor];
    self.sourceCodeTextView.tintColor = [AppStyle brightColor];
    self.sourceCodeTextView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.view.backgroundColor = [AppStyle darkColor];
    
    self.navigationItem.title = self.project.name;
    
    UIBarButtonItem *runButton = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStyleDone target:self action:@selector(onRunTapped:)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(onHelpTapped:)];
    self.navigationItem.rightBarButtonItems = @[runButton, helpButton];
    
    self.sourceCodeTextView.text = self.project.sourceCode ? self.project.sourceCode : @"";
    if ([self isExample] && ![AppController sharedController].isFullVersion)
    {
        self.sourceCodeTextView.pastable = NO;
    }
    self.sourceCodeTextView.layoutManager.allowsNonContiguousLayout = NO;
    self.sourceCodeTextView.delegate = self;
    
    self.sourceCodeTextView.keyboardAppearance = UIKeyboardAppearanceDark;
    self.sourceCodeTextView.keyboardToolbar.translucent = YES;
    self.sourceCodeTextView.keyboardToolbar.barStyle = UIBarStyleBlack;
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    AppController *app = [AppController sharedController];
    if (app.shouldShowTransferAlert)
    {
        app.shouldShowTransferAlert = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"The program wrote data to the transfer memory."
                                                                       message:@"Tap \"Paste from Transfer\" in the text edit menu to paste it into your source code."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = [AppStyle alertTintColor];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (self.project.isDefault.boolValue)
    {
        if ([app isUnshownInfoID:CoachMarkIDStart])
        {
            [app onShowInfoID:CoachMarkIDStart];
            [[CoachMarkView create] showWithText:@"Tap the Start button to run this program!" image:@"coach_start" container:self.navigationController.view complete:nil];
        }
    }
    else if (!self.project.isDefault.boolValue && self.wasEditedSinceOpened && self.sourceCodeTextView.text.length >= 200)
    {
        if ([app isUnshownInfoID:CoachMarkIDShare])
        {
            [app onShowInfoID:CoachMarkIDShare];
        [[CoachMarkView create] showWithText:@"Are you happy with your program? Share it on the LowRes Coder website!" image:@"coach_share" container:self.navigationController.view complete:nil];
        }
    }
    else if ([self.sourceCodeTextView.text isEqualToString:@""])
    {
        if ([app isUnshownInfoID:CoachMarkIDHelp])
        {
            [app onShowInfoID:CoachMarkIDHelp];
            [[CoachMarkView create] showWithText:@"Tap the Help button to learn how to create your own programs!" image:@"coach_help" container:self.navigationController.view complete:nil];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveProject];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize kbSize = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height - self.navigationController.toolbar.frame.size.height, 0.0);
    self.sourceCodeTextView.contentInset = insets;
    self.sourceCodeTextView.scrollIndicatorInsets = insets;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    self.sourceCodeTextView.contentInset = insets;
    self.sourceCodeTextView.scrollIndicatorInsets = insets;
}

- (void)saveProject
{
    [[ModelManager sharedManager] saveContext];
}

- (void)willSaveData:(NSNotification *)notification
{
    if (   self.project
        && ![self isExample]
        && ![self.sourceCodeTextView.text isEqualToString:self.project.sourceCode])
    {
        self.project.sourceCode = self.sourceCodeTextView.text;
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self isExample] && !self.examplesDontSaveWarningShowed)
    {
        self.examplesDontSaveWarningShowed = YES;
        
        NSString *message = [AppController sharedController].isFullVersion
        ? @"If you want to keep your changes, you can duplicate the program to have your own copy."
        : @"Anyway you can still experiment with the program.";
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Changes in example programs will not be saved."
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.sourceCodeTextView becomeFirstResponder];
        }]];
        
        alert.view.tintColor = [AppStyle alertTintColor];
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.wasEditedSinceOpened = YES;
    self.wasEditedSinceLastRun = YES;
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
        alert.view.tintColor = [AppStyle alertTintColor];
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
        
        alert.view.tintColor = [AppStyle alertTintColor];
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
        [[ModelManager sharedManager] duplicateProject:self.project sourceCode:self.sourceCodeTextView.text];
        [[ModelManager sharedManager] saveContext];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    alert.view.tintColor = [AppStyle alertTintColor];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onRenameTapped:(id)sender
{
    if (self.project.isDefault.boolValue)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example programs cannot be renamed." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = [AppStyle alertTintColor];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please enter new program name!" message:nil preferredStyle:UIAlertControllerStyleAlert];

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
        
        alert.view.tintColor = [AppStyle alertTintColor];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)onActionTapped:(id)sender
{
    if (self.sourceCodeTextView.text.length == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"This program is empty. Write something!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = [AppStyle alertTintColor];
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
    
    if (   ![AppController sharedController].isFullVersion
        && !self.project.isDefault.boolValue
        && sourceCode.countLines > EditorDemoMaxLines)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please upgrade to full version!"
                                                                       message:[NSString stringWithFormat:@"The free version can only run programs with up to %d lines.", EditorDemoMaxLines]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"More Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"Upgrade" sender:self];
        }]];
        alert.view.tintColor = [AppStyle alertTintColor];
        [self presentViewController:alert animated:YES completion:nil];

        return;
    }
    
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
        alert.view.tintColor = [AppStyle alertTintColor];
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
    vc.wasEditedSinceLastRun = self.wasEditedSinceLastRun;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];
    
    self.wasEditedSinceLastRun = NO;
}

- (BOOL)isExample
{
    return self.project.isDefault.boolValue;
}

@end
