//
//  RunnerViewController.m
//  Pixels
//
//  Created by Timo Kloss on 30/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "RunnerViewController.h"
#import "RunnerDelegate.h"
#import "Runner.h"
#import "OpenGLRendererView.h"
#import "Project.h"
#import "Gamepad.h"
#import "NSError+LowResCoder.h"
#import "NSString+Utils.h"
#import "EditorTextView.h"
#import "AudioPlayer.h"
#import "AppController.h"
#import "CoachMarkView.h"
#import "Runnable.h"
#import "VariableManager.h"
#import "UIViewController+LowResCoder.h"
#import <GameController/GameController.h>
#import <ReplayKit/ReplayKit.h>

NSString *const UserDefaultsFullscreenKey = @"fullscreen";
NSString *const UserDefaultsSoundEnabledKey = @"soundEnabled";
NSString *const UserDefaultsPersistentKey = @"persistent";

@interface RunnerViewController () <RunnerDelegate, UIKeyInput>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomButton;
@property (weak, nonatomic) IBOutlet UIButton *soundButton;
@property (weak, nonatomic) IBOutlet OpenGLRendererView *rendererView;
@property (weak, nonatomic) IBOutlet UIView *buttonContainer;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *buttonA;
@property (weak, nonatomic) IBOutlet UIButton *buttonB;
@property (weak, nonatomic) IBOutlet Gamepad *gamepad;
@property (weak, nonatomic) IBOutlet UIButton *backgroundButton;
@property (weak, nonatomic) IBOutlet UILabel *pausedLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintKeyboard;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintGamepad;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtons;

@property BOOL didAppearAlready;
@property (nonatomic) BOOL isFullscreen;
@property (nonatomic) BOOL soundEnabled;
@property Runner *runner;
@property int numPlayers;
@property (nonatomic) BOOL isPaused;
@property GCController *gameController;
@property BOOL dismissWhenFinished;
@property double audioVolume;
@property BOOL isKeyboardActive;

@end

@implementation RunnerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioVolume = 1.0;
    
    [self setGamepadModeWithPlayers:0];
    
    self.runner = [[Runner alloc] initWithRunnable:self.runnable];
    self.runner.delegate = self;
    self.runner.bootTime = [AppController sharedController].bootTime;
    self.rendererView.renderer = self.runner.renderer;
    
    self.pausedLabel.hidden = YES;
    
    // user defaults
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *fullscreenKey = [self projectKeyFor:UserDefaultsFullscreenKey];
    self.isFullscreen = [defaults objectForKey:fullscreenKey] ? [defaults boolForKey:fullscreenKey] : !self.runnable.usesGamepad;
    
    NSString *soundKey = [self projectKeyFor:UserDefaultsSoundEnabledKey];
    self.soundEnabled = [defaults objectForKey:soundKey] ? [defaults boolForKey:soundKey] : YES;

    NSString *persistentKey = [self projectKeyFor:UserDefaultsPersistentKey];
    NSDictionary *persistentVariables = [defaults dictionaryForKey:persistentKey];
    if (persistentVariables)
    {
        [self.runner.variables loadPersistentVariables:persistentVariables];
    }
    
    self.soundButton.hidden = !self.runnable.usesSound;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidConnect:) name:GCControllerDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidDisconnect:) name:GCControllerDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCControllerDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCControllerDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.didAppearAlready)
    {
        self.didAppearAlready = YES;
        
        if (self.runnable.usesSound)
        {
            [self.runner.audioPlayer start];
        }
        
        [self hideExitButtonAfterDelay];
        
        if (self.runnable.recordingMode != RecordingModeNone)
        {
            if (self.runnable.recordingMode == RecordingModeScreenAndMic)
            {
                // less volume when recording voice
                self.audioVolume = 0.25;
                self.runner.audioPlayer.volume = self.audioVolume;
            }
            [[RPScreenRecorder sharedRecorder] startRecordingWithMicrophoneEnabled:(self.runnable.recordingMode == RecordingModeScreenAndMic) handler:^(NSError * _Nullable error) {
                [self run];
            }];
        }
        else
        {
            [self run];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.runner.audioPlayer stop];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.isFullscreen forKey:[self projectKeyFor:UserDefaultsFullscreenKey]];
    [defaults setBool:self.soundEnabled forKey:[self projectKeyFor:UserDefaultsSoundEnabledKey]];
    
    if (!self.runner.isFinished && !self.runner.endRequested)
    {
        [self requestEnd];
    }
}

- (void)viewWillLayoutSubviews
{
    [self updateDynamicConstraints];
}

- (NSString *)projectKeyFor:(NSString *)key
{
    NSString *projectKey;
    if (self.project.isDefault.boolValue)
    {
        projectKey = [NSString stringWithFormat:@"%@ %@", self.project.name, key];
    }
    else
    {
        projectKey = [NSString stringWithFormat:@"%f %@", self.project.createdAt.timeIntervalSinceReferenceDate, key];
    }
    return projectKey;
}

- (void)gameControllerDidConnect:(NSNotification *)notification
{
    [self updateGamepads];
}

- (void)gameControllerDidDisconnect:(NSNotification *)notification
{
    [self updateGamepads];
    
    if (!self.gameController && !self.isPaused)
    {
        [self setIsPaused:YES message:@"GAME CONTROLLER DISCONNECTED, PAUSED"];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect kbRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.constraintKeyboard.constant = kbRect.size.height;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.constraintKeyboard.constant = 0;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)onBackgroundTouchDown:(id)sender
{
    if (self.isPaused)
    {
        self.isPaused = NO;
    }
    else if (self.isKeyboardActive)
    {
        [self becomeFirstResponder];
    }
    else if (self.numPlayers > 0)
    {
        // show that gamepad should be used
        [UIView animateWithDuration:0.1 animations:^{
            self.gamepad.transform = CGAffineTransformMakeScale(1.1, 1.1);
            self.buttonA.transform = CGAffineTransformMakeScale(1.1, 1.1);
            self.buttonB.transform = CGAffineTransformMakeScale(1.1, 1.1);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.gamepad.transform = CGAffineTransformMakeScale(1.0, 1.0);
                self.buttonA.transform = CGAffineTransformMakeScale(1.0, 1.0);
                self.buttonB.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
        }];
    }
    [self showExitButtonWithHiding:YES];
}

- (void)showExitButtonWithHiding:(BOOL)hides
{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.exitButton.alpha = 0.5;
        self.zoomButton.alpha = 0.5;
        self.soundButton.alpha = 0.5;
    } completion:^(BOOL finished) {
        if (hides)
        {
            [self hideExitButtonAfterDelay];
        }
    }];
}

- (void)hideExitButtonAfterDelay
{
    [UIView animateWithDuration:3 delay:3 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.exitButton.alpha = 0.05;
        self.zoomButton.alpha = 0.05;
        self.soundButton.alpha = 0.05;
    } completion:^(BOOL finished) {
    }];
}

- (void)updateDynamicConstraints
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGSize windowSize = window.bounds.size;
    BOOL isPanorama = windowSize.width > windowSize.height;
    
    // renderer
    if (self.isFullscreen)
    {
        self.constraintWidth.constant = windowSize.width;
        self.constraintHeight.constant = windowSize.height;
        self.constraintTop.constant = 0;
        self.constraintTop.priority = UILayoutPriorityDefaultHigh;
    }
    else
    {
        CGFloat shortSize = MIN(windowSize.width, windowSize.height);
        CGFloat ratio = windowSize.width / windowSize.height;
        self.constraintWidth.constant = shortSize;
        self.constraintHeight.constant = shortSize;
        self.constraintTop.constant = (isPanorama || ratio >= 0.65) ? 0 : self.exitButton.bounds.size.height;
        if (self.runnable.usesGamepad)
        {
            self.constraintTop.priority = UILayoutPriorityDefaultHigh;
        }
        else
        {
            self.constraintTop.priority = UILayoutPriorityDefaultLow - 1;
        }
    }
    
    // gamepad
    CGFloat gamepadBottom = 11.0;
    if (windowSize.width >= 768.0)
    {
        gamepadBottom = 88.0;
    }
    else if (!self.isFullscreen)
    {
        if (isPanorama)
        {
            if (windowSize.width >= 568.0)
            {
                gamepadBottom = (windowSize.width >= 667.0) ? 88.0 : 44.0;
            }
        }
        else
        {
            if (windowSize.height >= 568)
            {
                gamepadBottom = (windowSize.height >= 667) ? 88.0 : 44.0;
            }
        }

    }
    self.constraintGamepad.constant = gamepadBottom;
    self.constraintButtons.constant = gamepadBottom - 10.0;
}

- (void)run
{
    // don't change icons for example projects
    self.rendererView.shouldMakeSnapshots = !self.project.isDefault.boolValue;// && (self.project.iconData == nil || self.wasEditedSinceLastRun);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        
        Runner *runner = self.runner;
        
        // fix random seed
        srandom(0);
        
        while (!runner.isFinished && !runner.error)
        {
            if (self.isPaused)
            {
                [NSThread sleepForTimeInterval:0.1];
            }
            else
            {
                @autoreleasepool {
                    [runner runCommand];
                }
            }
        }
        
        [self setKeyboardActive:NO];
        
        if (runner.error && self.view.superview)
        {
            // runtime error!
            RunnerViewController __weak *weakSelf = self;
            NSString *line = [self.project.sourceCode substringWithLineAtIndex:runner.error.programPosition];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:runner.error.localizedDescription message:line preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [weakSelf finish];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            });
            
            self.dismissWhenFinished = NO;
        }
        
        [self updateRendererView];
        
        // snapshots
        if (self.project.iconData == nil || (self.wasEditedSinceLastRun && !self.project.isIconLocked.boolValue))
        {
            UIImage *image = [self.rendererView imageFromBestSnapshot];
            if (image)
            {
                self.project.iconData = UIImagePNGRepresentation(image);
            }
        }
        self.project.temporarySnapshots = [self.rendererView imagesFromSnapshots:20];
        
        // transfer
        NSString *transfer = [runner transferResult];
        if (transfer)
        {
            [EditorTextView setTransferText:transfer];
            [AppController sharedController].shouldShowTransferAlert = YES;
        }
        
        // persistent variables
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *persistentVariables = [runner.variables getPersistentVariables];
        if (persistentVariables)
        {
            [defaults setObject:persistentVariables forKey:[self projectKeyFor:UserDefaultsPersistentKey]];
        }

        // dismiss view if user tapped exit button
        if (self.dismissWhenFinished)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finish];
            });
        }
        
    });
}

- (void)requestEnd
{
    self.runner.endRequested = YES;
    if (self.isPaused)
    {
        self.isPaused = NO;
    }
}

- (void)finish
{
    if (self.runnable.recordingMode != RecordingModeNone && [RPScreenRecorder sharedRecorder].recording)
    {
        __weak RunnerViewController *weakSelf = self;
        [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            
            if (error)
            {
                [weakSelf showAlertWithTitle:@"Could not record video" message:error.localizedDescription block:^{
                    [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }];
            }
            else
            {
                [AppController sharedController].replayPreviewViewController = previewViewController;
                [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }
            
        }];
    }
    else
    {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)onExitTapped:(id)sender
{
    self.dismissWhenFinished = YES;
    if (self.runner.isFinished)
    {
        [self finish];
    }
    else
    {
        [self requestEnd];
    }
}

- (IBAction)onZoomTapped:(id)sender
{
    self.isFullscreen = !self.isFullscreen;
    [self showExitButtonWithHiding:YES];
    
    [self.containerView layoutIfNeeded];
    [self updateDynamicConstraints];
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)onSoundTapped:(id)sender
{
    self.soundEnabled = !self.soundEnabled;
    [self showExitButtonWithHiding:YES];
}

- (IBAction)onPauseTapped:(id)sender
{
    if (![self.runner handlePauseButton])
    {
        self.isPaused = !self.isPaused;
    }
}

- (void)setIsPaused:(BOOL)isPaused
{
    [self setIsPaused:isPaused message:@"PAUSED"];
}

- (void)setIsPaused:(BOOL)isPaused message:(NSString *)message
{
    _isPaused = isPaused;
    self.pausedLabel.hidden = !isPaused;
    self.rendererView.hidden = isPaused;
    [self updateOnScreenGamepads];
    if (isPaused)
    {
        self.runner.audioPlayer.volume = 0.0;
        self.pausedLabel.text = message;
        [self performSelector:@selector(togglePausedLabel) withObject:nil afterDelay:0.5];
        [self showExitButtonWithHiding:YES];
        [self resignFirstResponder];
    }
    else
    {
        self.runner.audioPlayer.volume = self.soundEnabled ? self.audioVolume : 0.0;
    }
}

- (void)togglePausedLabel
{
    if (self.isPaused)
    {
        self.pausedLabel.hidden = !self.pausedLabel.hidden;
        [self performSelector:@selector(togglePausedLabel) withObject:nil afterDelay:0.5];
    }
}

- (void)setIsFullscreen:(BOOL)isFullscreen
{
    _isFullscreen = isFullscreen;
    UIImage *image = [UIImage imageNamed:(isFullscreen ? @"zoom_on" : @"zoom_off")];
    [self.zoomButton setImage:image forState:UIControlStateNormal];
}

- (void)setSoundEnabled:(BOOL)soundEnabled
{
    _soundEnabled = soundEnabled;
    UIImage *image = [UIImage imageNamed:(soundEnabled ? @"sound_on" : @"sound_off")];
    [self.soundButton setImage:image forState:UIControlStateNormal];
    
    self.runner.audioPlayer.volume = soundEnabled ? self.audioVolume : 0.0;
}

- (void)runnerLog:(NSString *)message
{
    NSLog(@"%@", message);
}

- (void)updateRendererView
{
    [self.rendererView updateSnapshots];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rendererView setNeedsDisplay];
    });
}

- (BOOL)isButtonDown:(ButtonType)type
{
    GCGamepad *gamePad = self.gameController.gamepad;
    GCControllerDirectionPad *extDirPad = self.gameController.extendedGamepad.leftThumbstick;
    
    switch (type)
    {
        case ButtonTypeUp: return self.gamepad.isDirUp || gamePad.dpad.up.pressed || extDirPad.up.pressed;
        case ButtonTypeDown: return self.gamepad.isDirDown || gamePad.dpad.down.pressed || extDirPad.down.pressed;
        case ButtonTypeLeft: return self.gamepad.isDirLeft || gamePad.dpad.left.pressed || extDirPad.left.pressed;
        case ButtonTypeRight: return self.gamepad.isDirRight || gamePad.dpad.right.pressed || extDirPad.right.pressed;
        case ButtonTypeA: return self.buttonA.isHighlighted || gamePad.buttonA.pressed || gamePad.buttonX.pressed || (self.backgroundButton.isHighlighted && self.numPlayers == 0);
        case ButtonTypeB: return self.buttonB.isHighlighted || gamePad.buttonB.pressed || gamePad.buttonY.pressed;
    }
}

- (int)currentGamepadFlags
{
    return [self isButtonDown:ButtonTypeUp]
        | ([self isButtonDown:ButtonTypeDown] << 1)
        | ([self isButtonDown:ButtonTypeLeft] << 2)
        | ([self isButtonDown:ButtonTypeRight] << 3)
        | ([self isButtonDown:ButtonTypeA] << 4)
        | ([self isButtonDown:ButtonTypeB] << 5);
}

- (void)setGamepadModeWithPlayers:(int)players
{
    self.numPlayers = players;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateGamepads];
    });
}

- (void)updateGamepads
{
    // find connected game controller
    self.gameController = nil;
    NSArray *gameControllers = [GCController controllers];
    if (gameControllers.count > 0)
    {
        for (GCController *gameController in gameControllers)
        {
            if (gameController.playerIndex == 0)
            {
                self.gameController = gameController;
                break;
            }
            else if (gameController.isAttachedToDevice)
            {
                self.gameController = gameController;
                self.gameController.playerIndex = 0;
                break;
            }
        }
        if (!self.gameController)
        {
            self.gameController = gameControllers[0];
            self.gameController.playerIndex = 0;
        }
        
        __weak RunnerViewController *weakSelf = self;
        self.gameController.controllerPausedHandler = ^(GCController *gameController) {
            [weakSelf onPauseTapped:gameController];
        };
    }
    
    [self updateOnScreenGamepads];
}

- (void)updateOnScreenGamepads
{
    if (self.numPlayers == 0 || self.gameController || self.isPaused)
    {
        self.gamepad.hidden = YES;
        self.buttonContainer.hidden = YES;
    }
    else
    {
        self.gamepad.hidden = NO;
        self.buttonContainer.hidden = NO;
    }
}

- (void)setKeyboardActive:(BOOL)active
{
    self.isKeyboardActive = active;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (active)
        {
            [self becomeFirstResponder];
        }
        else
        {
            [self resignFirstResponder];
        }
    });
}

- (BOOL)canBecomeFirstResponder
{
    return self.isKeyboardActive;
}

- (UITextAutocorrectionType)autocorrectionType
{
    return UITextAutocorrectionTypeNo;
}

- (UITextSpellCheckingType)spellCheckingType
{
    return UITextSpellCheckingTypeNo;
}

- (UIKeyboardAppearance)keyboardAppearance
{
    return UIKeyboardAppearanceDark;
}

- (BOOL)hasText
{
    return YES;
}

- (void)insertText:(NSString *)text
{
    if (text.length > 0)
    {
        self.runner.lastKeyPressed = [text.uppercaseString characterAtIndex:0];
    }
}

- (void)deleteBackward
{
    self.runner.lastKeyPressed = '\b';
}

// this is from UITextInput, needed because of crash on iPhone 6 keyboard (left/right arrows)
- (UITextRange *)selectedTextRange
{
    return nil;
}

@end
