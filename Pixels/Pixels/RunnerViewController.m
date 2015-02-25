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
#import "ProgramException.h"
#import "NSString+Utils.h"
#import "EditorTextView.h"

@interface RunnerViewController ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet RendererView *rendererView;
@property (weak, nonatomic) IBOutlet UIButton *buttonA;
@property (weak, nonatomic) IBOutlet UIButton *buttonB;
@property (weak, nonatomic) IBOutlet Gamepad *gamepad;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintHeight;

@property UIPinchGestureRecognizer *pinchRecognizer;
@property UITapGestureRecognizer *tapRecognizer;

@property BOOL isRunning;
@property CGFloat scale;

@end

@implementation RunnerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scale = self.project.scale.floatValue;
    
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinchGesture:)];
    [self.containerView addGestureRecognizer:self.pinchRecognizer];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesture:)];
    [self.containerView addGestureRecognizer:self.tapRecognizer];
    
    [self setGamepadModeWithPlayers:0];
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
    self.project.scale = @(self.scale);
    self.isRunning = NO;
}

- (void)viewWillLayoutSubviews
{
    [self updateRendererScale];
}

- (void)onPinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        gestureRecognizer.scale = self.scale;
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        self.scale = MAX(0.25, MIN(1.0, gestureRecognizer.scale));
        [self updateRendererScale];
    }
}

- (void)onTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized)
    {
        [self showExitButtonWithHiding:YES];
    }
}

- (void)showExitButtonWithHiding:(BOOL)hides
{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.exitButton.alpha = 0.5;
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
    } completion:^(BOOL finished) {
    }];
}

- (void)updateRendererScale
{
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    BOOL panorama = (window.bounds.size.width > window.bounds.size.height);
    CGFloat longSide = panorama ? window.bounds.size.width : window.bounds.size.height;
    CGFloat shortSide = panorama ? window.bounds.size.height : window.bounds.size.width;
    
    longSide *= self.scale;
    if (shortSide > longSide)
    {
        shortSide = longSide;
    }
    
    if (panorama)
    {
        self.constraintWidth.constant = longSide;
        self.constraintHeight.constant = shortSide;
    }
    else
    {
        self.constraintWidth.constant = shortSide;
        self.constraintHeight.constant = longSide;
    }
}

- (void)run
{
    self.isRunning = YES;
    self.rendererView.shouldMakeThumbnail = !self.project.isDefault.boolValue; // don't change thumbnails for example projects
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        Runner *runner = [[Runner alloc] initWithRunnable:self.runnable];
        runner.delegate = self;
        self.rendererView.renderer = runner.renderer;

        @try
        {
            while (!runner.isFinished && self.isRunning)
            {
                [runner runCommand];
            }
        }
        @catch (ProgramException *exception)
        {
            // runtime error!
            NSString *line = [self.project.sourceCode substringWithLineAtIndex:exception.position];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:exception.reason message:line preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }]];
            alert.view.tintColor = self.view.tintColor;
            [self presentViewController:alert animated:YES completion:nil];

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
        }
    });
}

- (IBAction)onExitTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
    switch (type)
    {
        case ButtonTypeUp: return self.gamepad.isDirUp;
        case ButtonTypeDown: return self.gamepad.isDirDown;
        case ButtonTypeLeft: return self.gamepad.isDirLeft;
        case ButtonTypeRight: return self.gamepad.isDirRight;
        case ButtonTypeA: return self.buttonA.isHighlighted;
        case ButtonTypeB: return self.buttonB.isHighlighted;
    }
}

- (int)currentGamepadFlags
{
    return self.gamepad.isDirUp | (self.gamepad.isDirDown << 1) | (self.gamepad.isDirLeft << 2) | (self.gamepad.isDirRight << 3) | (self.buttonA.isHighlighted << 4) | (self.buttonB.isHighlighted << 5);
}

- (void)setGamepadModeWithPlayers:(int)players
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (players >= 1)
        {
            self.gamepad.hidden = NO;
            self.buttonA.hidden = NO;
            self.buttonB.hidden = NO;
        }
        else
        {
            self.gamepad.hidden = YES;
            self.buttonA.hidden = YES;
            self.buttonB.hidden = YES;
        }
    });
}

@end
