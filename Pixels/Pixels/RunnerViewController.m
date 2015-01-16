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
#import "Joypad.h"
#import "CompilerException.h"

@interface RunnerViewController ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet RendererView *rendererView;
@property (weak, nonatomic) IBOutlet UIButton *buttonA;
@property (weak, nonatomic) IBOutlet UIButton *buttonB;
@property (weak, nonatomic) IBOutlet Joypad *joypad;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintHeight;

@property UIPinchGestureRecognizer *pinchRecognizer;

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
}

/*
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
*/

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self run];
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
    self.rendererView.shouldMakeThumbnail = YES;
    
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
        @catch (CompilerException *exception)
        {
            // runtime error!
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:exception.reason preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }]];
            [self presentViewController:alert animated:YES completion:nil];

        }
        [self updateRendererView];
        
        // thumbnail
        UIImage *thumb = [self.rendererView imageFromBestSnapshot];
        if (thumb)
        {
            self.project.iconData = UIImagePNGRepresentation(thumb);
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
        case ButtonTypeUp: return self.joypad.isDirUp;
        case ButtonTypeDown: return self.joypad.isDirDown;
        case ButtonTypeLeft: return self.joypad.isDirLeft;
        case ButtonTypeRight: return self.joypad.isDirRight;
        case ButtonTypeA: return self.buttonA.isHighlighted;
        case ButtonTypeB: return self.buttonB.isHighlighted;
    }
}

@end
