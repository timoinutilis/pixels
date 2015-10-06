//
//  ViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "EditorViewController.h"
#import "Runnable.h"
#import "Runner.h"
#import "ModelManager.h"
#import "RunnerViewController.h"
#import "ActivityItemSource.h"
#import "NSString+Utils.h"
#import "EditorTextView.h"
#import "AppController.h"
#import "CoachMarkView.h"
#import "AppStyle.h"
#import "UIViewController+LowResCoder.h"
#import "NSError+LowResCoder.h"
#import "Compiler.h"
#import "CommPostViewController.h"
#import "CommunityModel.h"
#import "ShareViewController.h"
#import "SearchToolbar.h"

int const EditorDemoMaxLines = 24;
NSString *const CoachMarkIDStart = @"CoachMarkIDStart";
NSString *const CoachMarkIDShare = @"CoachMarkIDShare";
NSString *const CoachMarkIDHelp = @"CoachMarkIDHelp";

static int s_editorInstancesCount = 0;


@interface EditorViewController () <SearchToolbarDelegate>

@property (weak, nonatomic) IBOutlet EditorTextView *sourceCodeTextView;
@property (weak, nonatomic) IBOutlet SearchToolbar *searchToolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchToolbarConstraint;


@property BOOL examplesDontSaveWarningShowed;
@property BOOL wasEditedSinceOpened;
@property BOOL wasEditedSinceLastRun;
@property CGFloat keyboardHeight;

@end

@implementation EditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    s_editorInstancesCount++;
    if (s_editorInstancesCount > 1)
    {
        @throw [NSException exceptionWithName:@"TooManyEditorInstances" reason:@"Too many editor instances" userInfo:nil];
    }
    
    UIBarButtonItem *startItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"start"] style:UIBarButtonItemStylePlain target:self action:@selector(onRunTapped:)];
    UIBarButtonItem *projectItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(onProjectTapped:)];
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(onSearchTapped:)];
    UIBarButtonItem *feedbackItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"feedback"] style:UIBarButtonItemStylePlain target:self action:@selector(onFeedbackTapped:)];
    
    self.navigationItem.rightBarButtonItems = @[startItem, searchItem, feedbackItem, projectItem];
    
    self.view.backgroundColor = [AppStyle editorColor];
    self.sourceCodeTextView.backgroundColor = [AppStyle editorColor];
    self.sourceCodeTextView.textColor = [AppStyle tintColor];
    self.sourceCodeTextView.tintColor = [AppStyle brightColor];
    self.sourceCodeTextView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.navigationItem.title = self.project.name;
    
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
    
    self.searchToolbar.searchDelegate = self;
    self.searchToolbarConstraint.constant = -self.searchToolbar.bounds.size.height;
    self.searchToolbar.hidden = YES;
    
    self.keyboardHeight = 0.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveData:) name:ModelManagerWillSaveDataNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerWillSaveDataNotification object:nil];
    
    s_editorInstancesCount--;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateEditorInsets];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.sourceCodeTextView flashScrollIndicators];
    
    AppController *app = [AppController sharedController];
    if (app.shouldShowTransferAlert)
    {
        app.shouldShowTransferAlert = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"The program wrote data to the transfer memory."
                                                                       message:@"Tap \"Paste from Transfer\" in the text edit menu to paste it into your source code."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
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
            [[CoachMarkView create] showWithText:@"Are you happy with your program? Share it with the community!" image:@"coach_share" container:self.navigationController.view complete:nil];
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
    self.keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [self updateEditorInsets];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardHeight = 0.0;
    [self updateEditorInsets];
}

- (void)updateEditorInsets
{
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    if (self.keyboardHeight > 0.0)
    {
        insets.bottom = self.keyboardHeight;
    }
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
        [ModelManager sharedManager].debugSaveCount++;
        self.project.sourceCode = self.sourceCodeTextView.text.uppercaseString;
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self isExample] && !self.examplesDontSaveWarningShowed)
    {
        self.examplesDontSaveWarningShowed = YES;
        
        EditorViewController __weak *weakSelf = self;
        NSString *message = [AppController sharedController].isFullVersion
        ? @"If you want to keep your changes, you can duplicate the program to have your own copy."
        : @"Anyway you can still experiment with the program.";
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Changes in example programs will not be saved."
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf.sourceCodeTextView becomeFirstResponder];
        }]];
        
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

- (void)onSearchTapped:(id)sender
{
    [self.view layoutIfNeeded];
    BOOL wasVisible = (self.searchToolbarConstraint.constant == 0.0);
    if (wasVisible)
    {
        self.searchToolbarConstraint.constant = -self.searchToolbar.bounds.size.height;
        [self.searchToolbar endEditing:YES];
    }
    else
    {
        self.searchToolbar.hidden = NO;
        self.searchToolbarConstraint.constant = 0.0;
    }
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (wasVisible && self.searchToolbarConstraint.constant != 0.0)
        {
            self.searchToolbar.hidden = YES;
        }
    }];
}

- (void)onProjectTapped:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak EditorViewController *weakSelf = self;

    UIAlertAction *shareCommAction = [UIAlertAction actionWithTitle:@"Publish in Community" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [weakSelf onShareTapped:sender community:YES];
    }];
    [alert addAction:shareCommAction];

    UIAlertAction *shareMenuAction = [UIAlertAction actionWithTitle:@"Share Source Code" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [weakSelf onShareTapped:sender community:NO];
    }];
    [alert addAction:shareMenuAction];

    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [weakSelf onRenameTapped];
    }];
    [alert addAction:renameAction];

    UIAlertAction *duplicateAction = [UIAlertAction actionWithTitle:@"Duplicate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [weakSelf onDuplicateTapped];
    }];
    [alert addAction:duplicateAction];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        [weakSelf onDeleteTapped];
    }];
    [alert addAction:deleteAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    alert.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onDeleteTapped
{
    if (self.project.isDefault.boolValue)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example programs cannot be deleted." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (self.sourceCodeTextView.text.length == 0)
    {
        [self deleteProject];
    }
    else
    {
        EditorViewController __weak *weakSelf = self;
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you really want to delete this program?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [weakSelf deleteProject];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)deleteProject
{
    [[ModelManager sharedManager] deleteProject:self.project];
    self.project = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onDuplicateTapped
{
    EditorViewController __weak *weakSelf = self;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you want to make a copy of this program?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Duplicate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[ModelManager sharedManager] duplicateProject:weakSelf.project sourceCode:weakSelf.sourceCodeTextView.text];
        [[ModelManager sharedManager] saveContext];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onRenameTapped
{
    if (self.project.isDefault.boolValue)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example programs cannot be renamed." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        EditorViewController __weak *weakSelf = self;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please enter new program name!" message:nil preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = weakSelf.project.name;
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            weakSelf.project.name = ((UITextField *)alert.textFields[0]).text;
            weakSelf.navigationItem.title = weakSelf.project.name;
            [weakSelf saveProject];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onFeedbackTapped:(id)sender
{
    if (!self.project.postId)
    {
        [self showAlertWithTitle:@"This program is not connected to any post in the community." message:nil block:nil];
    }
    else
    {
        LCCPost *post = [LCCPost objectWithoutDataWithClassName:[LCCPost parseClassName] objectId:self.project.postId];
        [self showPost:post];
    }
}

- (void)showPost:(LCCPost *)post
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    CommPostViewController *vc = (CommPostViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CommPostView"];
    [vc setPost:post mode:CommPostModePost];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onShareTapped:(id)sender community:(BOOL)community
{
    if (self.sourceCodeTextView.text.length == 0)
    {
        [self showAlertWithTitle:@"This program is empty" message:@"Please write something!" block:nil];
    }
    else
    {
        [self saveProject];
        
        if (community)
        {
            UIViewController *vc = [ShareViewController createShareWithDelegate:nil project:self.project];
            [self presentViewController:vc animated:YES completion:nil];
        }
        else
        {
            ActivityItemSource *item = [[ActivityItemSource alloc] init];
            item.project = self.project;
            
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[item] applicationActivities:nil];
            
            activityVC.popoverPresentationController.barButtonItem = sender;
            [self presentViewController:activityVC animated:YES completion:nil];
        }
    }
}

#pragma mark - Search and Replace

- (void)searchToolbar:(SearchToolbar *)searchToolbar didSearch:(NSString *)findText backwards:(BOOL)backwards
{
    NSString *sourceText = self.sourceCodeTextView.text;
    
    NSRange selectedRange = self.sourceCodeTextView.selectedRange;
    NSUInteger startIndex;
    BOOL didRestart = NO;
    if (backwards)
    {
        startIndex = selectedRange.location;
        if (startIndex == 0)
        {
            startIndex = sourceText.length;
            didRestart = YES;
        }
    }
    else
    {
        startIndex = selectedRange.location + selectedRange.length;
        if (startIndex == sourceText.length)
        {
            startIndex = 0;
            didRestart = YES;
        }
    }
    BOOL found = [self find:findText backwards:backwards startIndex:startIndex];
    if (!found && !didRestart)
    {
        startIndex = backwards ? sourceText.length : 0;
        [self find:findText backwards:backwards startIndex:startIndex];
    }
}

- (BOOL)find:(NSString *)findText backwards:(BOOL)backwards startIndex:(NSUInteger)startIndex
{
    NSString *sourceText = self.sourceCodeTextView.text;
    
    NSRange searchRange = backwards ? NSMakeRange(0, startIndex) : NSMakeRange(startIndex, sourceText.length - startIndex);
    NSRange resultRange = [sourceText rangeOfString:findText options:(backwards ? NSCaseInsensitiveSearch | NSBackwardsSearch : NSCaseInsensitiveSearch) range:searchRange];
    if (resultRange.location != NSNotFound)
    {
        self.sourceCodeTextView.selectedRange = resultRange;
        [self.sourceCodeTextView becomeFirstResponder];
        [self.sourceCodeTextView scrollRangeToVisible:resultRange];
        return YES;
    }
    return NO;
}

- (void)searchToolbar:(SearchToolbar *)searchToolbar didReplace:(NSString *)findText with:(NSString *)replaceText
{
    NSString *sourceText = self.sourceCodeTextView.text;
    
    NSRange selectedRange = self.sourceCodeTextView.selectedRange;
    if ([[sourceText substringWithRange:selectedRange] isEqualToString:findText])
    {
        // replace
        sourceText = [sourceText stringByReplacingCharactersInRange:selectedRange withString:replaceText];
        self.sourceCodeTextView.text = sourceText;
        self.sourceCodeTextView.selectedRange = NSMakeRange(selectedRange.location + replaceText.length, 0);
    }
    
    // find next
    [self searchToolbar:searchToolbar didSearch:findText backwards:NO];
}

#pragma mark - Compile and run

- (void)runProgram
{
    NSString *sourceCode = self.sourceCodeTextView.text.uppercaseString;
    NSString *transferSourceCode = [EditorTextView transferText];
    
    if (   ![AppController sharedController].isFullVersion
        && !self.project.isDefault.boolValue
        && sourceCode.countLines > EditorDemoMaxLines)
    {
        EditorViewController __weak *weakSelf = self;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please upgrade to full version!"
                                                                       message:[NSString stringWithFormat:@"The free version can only run programs with up to %d lines.", EditorDemoMaxLines]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"More Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf performSegueWithIdentifier:@"Upgrade" sender:weakSelf];
        }]];
        [self presentViewController:alert animated:YES completion:nil];

        return;
    }
    
    NSArray *transferDataNodes;
    
    if (transferSourceCode.length > 0)
    {
        Runnable *runnable = [Compiler compileSourceCode:transferSourceCode error:nil];
        if (runnable)
        {
            transferDataNodes = runnable.dataNodes;
        }
    }
    
    NSError *error;
    
    Runnable *runnable = [Compiler compileSourceCode:sourceCode error:&error];
    if (runnable)
    {
        runnable.transferDataNodes = transferDataNodes;
        [self run:runnable];
    }
    else if (error)
    {
        NSUInteger errorPosition = error.programPosition;
        NSString *line = [sourceCode substringWithLineAtIndex:errorPosition];
        EditorViewController __weak *weakSelf = self;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:error.localizedDescription message:line preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Go to Error" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSRange range = NSMakeRange(errorPosition, 0);
            weakSelf.sourceCodeTextView.selectedRange = range;
            [weakSelf.sourceCodeTextView becomeFirstResponder];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
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
