//
//  RunnerViewController.m
//  Pixels
//
//  Created by Timo Kloss on 30/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "RunnerViewController.h"
#import "Runner.h"
#import "RendererView.h"
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
#import <GameController/GameController.h>

NSString *const UserDefaultsFullscreenKey = @"fullscreen";
NSString *const UserDefaultsSoundEnabledKey = @"soundEnabled";
NSString *const UserDefaultsPersistentKey = @"persistent";

@interface RunnerViewController ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomButton;
@property (weak, nonatomic) IBOutlet UIButton *soundButton;
@property (weak, nonatomic) IBOutlet RendererView *rendererView;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *buttonA;
@property (weak, nonatomic) IBOutlet UIButton *buttonB;
@property (weak, nonatomic) IBOutlet Gamepad *gamepad;
@property (weak, nonatomic) IBOutlet UIButton *backgroundButton;
@property (weak, nonatomic) IBOutlet UILabel *pausedLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTop;

@property (nonatomic) BOOL isFullscreen;
@property (nonatomic) BOOL soundEnabled;
@property Runner *runner;
@property int numPlayers;
@property (nonatomic) BOOL isPaused;
@property GCController *gameController;
@property BOOL dismissWhenFinished;

@end

@implementation RunnerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setGamepadModeWithPlayers:0];
    
    self.runner = [[Runner alloc] initWithRunnable:self.runnable];
    self.runner.delegate = self;
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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCControllerDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCControllerDidDisconnectNotification object:nil];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self run];
    [self hideExitButtonAfterDelay];
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
    [self updateRendererConstraints];
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

- (IBAction)onBackgroundTouchDown:(id)sender
{
    if (self.isPaused)
    {
        self.isPaused = NO;
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

- (void)updateRendererConstraints
{
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    if (self.isFullscreen)
    {
        self.constraintWidth.constant = window.bounds.size.width;
        self.constraintHeight.constant = window.bounds.size.height;
        self.constraintTop.constant = 0;
        self.constraintTop.priority = UILayoutPriorityDefaultHigh;
    }
    else
    {
        BOOL isPanorama = window.bounds.size.width > window.bounds.size.height;
        CGFloat shortSize = MIN(window.bounds.size.width, window.bounds.size.height);
        CGFloat ratio = window.bounds.size.width / window.bounds.size.height;
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
}

- (void)run
{
    // don't change thumbnails for example projects
    self.rendererView.shouldMakeThumbnail = !self.project.isDefault.boolValue && (self.project.iconData == nil || self.wasEditedSinceLastRun);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        
        Runner *runner = self.runner;

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
        
        if (runner.error && self.view.superview)
        {
            // runtime error!
            RunnerViewController __weak *weakSelf = self;
            NSString *line = [self.project.sourceCode substringWithLineAtIndex:runner.error.programPosition];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:runner.error.localizedDescription message:line preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            });
            
            self.dismissWhenFinished = NO;
        }
        
        [self updateRendererView];
        
        // thumbnail
        UIImage *thumb = [self.rendererView imageFromBestSnapshot];
        if (thumb)
        {
            self.project.iconData = UIImagePNGRepresentation(thumb);
        }
        
        // transfer
        if (runner.transferStrings.count > 0)
        {
            NSString *transfer = [runner.transferStrings componentsJoinedByString:@"\n"];
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
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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

- (IBAction)onExitTapped:(id)sender
{
    self.dismissWhenFinished = YES;
    if (self.runner.isFinished)
    {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
    [self updateRendererConstraints];
    [UIView animateWithDuration:0.3 animations:^{
        [self.containerView layoutIfNeeded];
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
    }
    else
    {
        self.runner.audioPlayer.volume = self.soundEnabled ? 1.0 : 0.0;
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
    
    self.runner.audioPlayer.volume = soundEnabled ? 1.0 : 0.0;
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
        self.buttonA.hidden = YES;
        self.buttonB.hidden = YES;
        self.pauseButton.hidden = YES;
    }
    else
    {
        self.gamepad.hidden = NO;
        self.buttonA.hidden = NO;
        self.buttonB.hidden = NO;
        self.pauseButton.hidden = NO;
    }
}

@end
