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
#import "TabBarController.h"
#import "UITextView+Utils.h"
#import "HelpContent.h"
#import "IndexSideBar.h"
#import <ReplayKit/ReplayKit.h>

int const EditorDemoMaxLines = 24;
NSString *const CoachMarkIDStart = @"CoachMarkIDStart";
NSString *const CoachMarkIDShare = @"CoachMarkIDShare";
NSString *const CoachMarkIDHelp = @"CoachMarkIDHelp";

NSString *const InfoIDExample = @"InfoIDExample";
NSString *const InfoIDLongProgram = @"InfoIDLongProgram";
NSString *const InfoIDPaste = @"InfoIDPaste";

static int s_editorInstancesCount = 0;

typedef void(^InfoBlock)(void);


@interface EditorViewController () <SearchToolbarDelegate, EditorTextViewDelegate, UITextViewDelegate, RPPreviewViewControllerDelegate>

@property (weak, nonatomic) IBOutlet EditorTextView *sourceCodeTextView;
@property (weak, nonatomic) IBOutlet SearchToolbar *searchToolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchToolbarConstraint;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoViewConstraint;
@property (weak, nonatomic) IBOutlet IndexSideBar *indexSideBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *indexSideBarConstraint;

@property UIBarButtonItem *projectItem;

@property BOOL wasEditedSinceOpened;
@property BOOL wasEditedSinceLastRun;
@property CGRect keyboardRect;
@property NSInteger numLines;
@property NSString *spacesToInsert;
@property BOOL shouldUpdateSideBar;
@property (strong) InfoBlock infoBlock;
@property NSString *infoId;

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
    
    UIBarButtonItem *startItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(onRunTapped:)];
    self.projectItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onProjectTapped:)];
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(onSearchTapped:)];
    UIBarButtonItem *feedbackItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"feedback"] style:UIBarButtonItemStylePlain target:self action:@selector(onFeedbackTapped:)];
    
    self.navigationItem.rightBarButtonItems = @[startItem, searchItem, feedbackItem, self.projectItem];
    
    self.view.backgroundColor = [AppStyle editorColor];
    self.sourceCodeTextView.backgroundColor = [AppStyle editorColor];
    self.sourceCodeTextView.textColor = [AppStyle tintColor];
    self.sourceCodeTextView.tintColor = [AppStyle brightColor];
    self.sourceCodeTextView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.navigationItem.title = self.project.name;
    
    self.sourceCodeTextView.text = self.project.sourceCode ? self.project.sourceCode : @"";
    self.sourceCodeTextView.layoutManager.allowsNonContiguousLayout = NO;
    self.sourceCodeTextView.delegate = self;
    self.sourceCodeTextView.editorDelegate = self;
    
    self.sourceCodeTextView.keyboardAppearance = UIKeyboardAppearanceDark;
    self.sourceCodeTextView.keyboardToolbar.translucent = YES;
    self.sourceCodeTextView.keyboardToolbar.barStyle = UIBarStyleBlack;
    
    self.searchToolbar.searchDelegate = self;
    self.searchToolbarConstraint.constant = -self.searchToolbar.bounds.size.height;
    self.searchToolbar.hidden = YES;
    
    self.infoView.backgroundColor = [AppStyle warningColor];
    self.infoView.layer.shadowRadius = 1.0;
    self.infoView.layer.shadowOpacity = 1.0;
    self.infoView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.infoLabel.textColor = [AppStyle brightColor];
    self.infoViewConstraint.constant = -self.infoView.bounds.size.height;
    self.infoView.hidden = YES;
    
    self.indexSideBar.textView = self.sourceCodeTextView;
    
    self.keyboardRect = CGRectZero;
    
    self.numLines = self.sourceCodeTextView.text.countLines;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveData:) name:ModelManagerWillSaveDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpgrade:) name:UpgradeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerWillSaveDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UpgradeNotification object:nil];
    
    s_editorInstancesCount--;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateEditorInsets];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.indexSideBar update];
    [self.sourceCodeTextView flashScrollIndicators];
    
    AppController *app = [AppController sharedController];
    if (app.replayPreviewViewController)
    {
        // Recorded Video!
        app.replayPreviewViewController.previewControllerDelegate = self;
        app.replayPreviewViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:app.replayPreviewViewController animated:YES completion:nil];
    }
    else if (app.shouldShowTransferAlert)
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
//        if ([app isUnshownInfoID:CoachMarkIDStart])
        {
            [app onShowInfoID:CoachMarkIDStart];
            CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Tap the Play button to run this program!" complete:nil];
            [coachMark setTargetNavBar:self.navigationController.navigationBar itemIndex:0];
            [coachMark show];
        }
    }
    else if (!self.project.isDefault.boolValue && self.wasEditedSinceOpened && self.sourceCodeTextView.text.length >= 200)
    {
        if ([app isUnshownInfoID:CoachMarkIDShare])
        {
            [app onShowInfoID:CoachMarkIDShare];
            CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Are you happy with your program? Share it with the community!" complete:nil];
            [coachMark setTargetNavBar:self.navigationController.navigationBar itemIndex:3];
            [coachMark show];
        }
    }
    else if ([self.sourceCodeTextView.text isEqualToString:@""])
    {
        if ([app isUnshownInfoID:CoachMarkIDHelp])
        {
            [app onShowInfoID:CoachMarkIDHelp];
            CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Go to the Help tab to learn how to create your own programs!" complete:nil];
            [coachMark setTargetTabBar:[AppController sharedController].tabBarController.tabBar itemIndex:1];
            [coachMark show];
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
    self.keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self updateEditorInsets];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self updateEditorInsets];
}

- (void)updateEditorInsets
{
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    if (self.keyboardRect.size.height > 0.0)
    {
        CGRect rect = [self.navigationController.view convertRect:self.sourceCodeTextView.frame fromView:self.view];
        CGFloat textBottomY = rect.origin.y + rect.size.height;
        if (self.keyboardRect.origin.y < textBottomY)
        {
            insets.bottom = textBottomY - self.keyboardRect.origin.y;
        }
    }
    self.sourceCodeTextView.contentInset = insets;
    self.sourceCodeTextView.scrollIndicatorInsets = insets;
    self.indexSideBarConstraint.constant = -insets.bottom;
}

- (void)saveProject
{
    [[ModelManager sharedManager] saveContext];
}

- (void)willSaveData:(NSNotification *)notification
{
    if (   self.project
        && ![self isExample]
        && ([AppController sharedController].isFullVersion || self.sourceCodeTextView.text.countLines <= EditorDemoMaxLines)
        && ![self.sourceCodeTextView.text isEqualToString:self.project.sourceCode])
    {
        [ModelManager sharedManager].debugSaveCount++;
        self.project.sourceCode = self.sourceCodeTextView.text.uppercaseString;
    }
}

- (void)didUpgrade:(NSNotification *)notification
{
    if (self.infoId && self.infoId != InfoIDExample)
    {
        [self hideInfo];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self isExample])
    {
        if (self.infoId != InfoIDExample)
        {
            __weak EditorViewController *weakSelf = self;
            [self showInfo:@"Changes in example programs will not be saved.\nMake a copy?" infoId:InfoIDExample block:^{
                [weakSelf onDuplicateTapped];
            }];
        }
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.wasEditedSinceOpened = YES;
    self.wasEditedSinceLastRun = YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *oldText = [textView.text substringWithRange:range];
    NSInteger oldTextLineBreaks = [oldText countChar:'\n'];
    NSInteger newTextLineBreaks = [text countChar:'\n'];
    NSInteger newNumLines = self.numLines - oldTextLineBreaks + newTextLineBreaks;
    
    if (![AppController sharedController].isFullVersion)
    {
        __weak EditorViewController *weakSelf = self;
        if (text.length > 1 && newNumLines > EditorDemoMaxLines)
        {
            [self showInfo:@"Cannot paste into long programs.\nShow information about full version?" infoId:InfoIDPaste block:^{
                [weakSelf performSegueWithIdentifier:@"Upgrade" sender:weakSelf];
            }];
            return NO;
        }
        
        if (self.infoId != InfoIDLongProgram && ![self isExample] && newNumLines > EditorDemoMaxLines)
        {
            [self showInfo:@"Changes in long programs will not be saved.\nShow information about full version?" infoId:InfoIDLongProgram block:^{
                [weakSelf performSegueWithIdentifier:@"Upgrade" sender:weakSelf];
            }];
        }
        else if ([self isExample])
        {
            if (self.infoId != InfoIDExample)
            {
                [self showInfo:@"Changes in example programs will not be saved.\nMake a copy?" infoId:InfoIDExample block:^{
                    [weakSelf onDuplicateTapped];
                }];
            }
        }
        else if (newNumLines <= EditorDemoMaxLines || self.infoId == InfoIDPaste)
        {
            [self hideInfo];
        }
    }
    
    self.numLines = newNumLines;
    
    // check for indent
    self.spacesToInsert = nil;
    if ([text isEqualToString:@"\n"])
    {
        NSRange lineRange = [textView.text lineRangeForRange:textView.selectedRange];
        for (NSInteger i = 0; i < lineRange.length; i++)
        {
            if ([textView.text characterAtIndex:(lineRange.location + i)] != ' ')
            {
                lineRange.length = i;
                self.spacesToInsert = [textView.text substringWithRange:lineRange];
                break;
            }
        }
    }
    
    // check for new or deleted label
    if (   [text rangeOfString:@":"].location != NSNotFound
        || (range.length > 0 && [oldText rangeOfString:@":"].location != NSNotFound) )
    {
        self.shouldUpdateSideBar = YES;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    // indent
    if (self.spacesToInsert)
    {
        NSString *spaces = self.spacesToInsert;
        self.spacesToInsert = nil;
        [textView insertText:spaces];
    }
    
    // side bar
    if (self.shouldUpdateSideBar)
    {
        // immediate update
        self.shouldUpdateSideBar = NO;
        [self.indexSideBar update];
    }
    else
    {
        // update later
        self.indexSideBar.shouldUpdateOnTouch = YES;
    }
}

- (void)onRunTapped:(id)sender
{
    [self runProgramWithRecordingMode:RecordingModeNone];
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
    
    UIAlertAction *videoMenuAction = [UIAlertAction actionWithTitle:@"Record Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [weakSelf onRecordVideoTapped:sender];
    }];
    [alert addAction:videoMenuAction];
    
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
    else if (![AppController sharedController].isFullVersion && self.sourceCodeTextView.text.countLines > EditorDemoMaxLines)
    {
        EditorViewController __weak *weakSelf = self;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please upgrade to full version!"
                                                                       message:[NSString stringWithFormat:@"The free version can only share programs with up to %d lines.", EditorDemoMaxLines]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"More Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf performSegueWithIdentifier:@"Upgrade" sender:weakSelf];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
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

- (void)onRecordVideoTapped:(id)sender
{
    if (![RPScreenRecorder class])
    {
        [self showAlertWithTitle:@"Recording is not available" message:@"Please update your device to iOS 9 or higher!" block:nil];
    }
    else if (![RPScreenRecorder sharedRecorder].available)
    {
        [self showAlertWithTitle:@"Recording is not available" message:@"Your device doesn't support screen recording or the recorder is currently not usable." block:nil];
    }
    else
    {
        __weak EditorViewController *weakSelf = self;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Video Recording"
                                                                       message:@"Please make videos in landscape orientation and in fullscreen mode whenever possible."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Record Screen & Microphone" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf runProgramWithRecordingMode:RecordingModeScreenAndMic];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Record Screen Only" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf runProgramWithRecordingMode:RecordingModeScreen];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        [AppController sharedController].replayPreviewViewController = nil;
    });
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
        [self.sourceCodeTextView scrollSelectedRangeToVisible];
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
        if (!self.sourceCodeTextView.isFirstResponder)
        {
            // activate editor
            [self.sourceCodeTextView becomeFirstResponder];
            [self.sourceCodeTextView scrollSelectedRangeToVisible];
            return;
        }
        // replace
        sourceText = [sourceText stringByReplacingCharactersInRange:selectedRange withString:replaceText];
        self.sourceCodeTextView.text = sourceText;
        self.sourceCodeTextView.selectedRange = NSMakeRange(selectedRange.location + replaceText.length, 0);
    }
    
    // find next
    [self searchToolbar:searchToolbar didSearch:findText backwards:NO];
}

#pragma mark - EditorTextView

- (void)editorTextView:(EditorTextView *)editorTextView didSelectHelpWithRange:(NSRange)range
{
    if ([editorTextView.text characterAtIndex:range.location + range.length] == '$')
    {
        // include "$"
        range.length++;
    }
    NSString *text = [editorTextView.text substringWithRange:range];
    HelpContent *helpContent = [AppController sharedController].helpContent;
    NSArray *results = [helpContent chaptersForSearchText:text];
    if (results.count == 1)
    {
        HelpChapter *chapter = results.firstObject;
        [[AppController sharedController].tabBarController showHelpForChapter:chapter.htmlChapter];
    }
    else if (results.count > 1)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        for (HelpChapter *chapter in results)
        {
            [alert addAction:[UIAlertAction actionWithTitle:chapter.title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[AppController sharedController].tabBarController showHelpForChapter:chapter.htmlChapter];
            }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        UIPopoverPresentationController *ppc = alert.popoverPresentationController;
        if (ppc)
        {
            ppc.sourceView = self.sourceCodeTextView;
            ppc.sourceRect = [self.sourceCodeTextView.layoutManager boundingRectForGlyphRange:range inTextContainer:self.sourceCodeTextView.textContainer];
            ppc.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        }
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        NSString *title = [NSString stringWithFormat:@"%@ is not a keyword.", text];
        [self showAlertWithTitle:title message:nil block:nil];
    }
}

#pragma mark - Info bar

- (void)showInfo:(NSString *)text infoId:(NSString *)infoId block:(InfoBlock)block
{
    self.infoBlock = block;
    self.infoId = infoId;
    
    if (self.infoViewConstraint.constant != 0.0)
    {
        self.infoLabel.text = text;
        [self.view layoutIfNeeded];
        self.infoView.hidden = NO;
        self.infoViewConstraint.constant = 0.0;

        [UIView animateWithDuration:0.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    else
    {
        [UIView transitionWithView:self.infoView duration:0.3 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
            self.infoLabel.text = text;
        } completion:nil];
    }
}

- (void)hideInfo
{
    self.infoBlock = nil;
    self.infoId = nil;
    
    if (self.infoViewConstraint.constant == 0.0)
    {
        [self.view layoutIfNeeded];
        self.infoViewConstraint.constant = -self.infoView.bounds.size.height;
        
        [UIView animateWithDuration:0.3 animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (self.infoViewConstraint.constant != 0.0)
            {
                self.infoView.hidden = YES;
            }
        }];
    }
}

- (IBAction)onInfoTapped:(id)sender
{
    if (self.infoBlock)
    {
        self.infoBlock();
    }
}

#pragma mark - Compile and run

- (void)runProgramWithRecordingMode:(RecordingMode)recordingMode
{
    NSString *sourceCode = self.sourceCodeTextView.text.uppercaseString;
    NSString *transferSourceCode = [EditorTextView transferText];
    
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
        runnable.recordingMode = recordingMode;
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
