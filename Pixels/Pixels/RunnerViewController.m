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

@interface RunnerViewController ()

@property (weak, nonatomic) IBOutlet RendererView *rendererView;
@property (weak, nonatomic) IBOutlet UIButton *buttonA;
@property (weak, nonatomic) IBOutlet UIButton *buttonB;
@property (weak, nonatomic) IBOutlet Joypad *joypad;

@property BOOL isRunning;

@end

@implementation RunnerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    self.isRunning = NO;
}

- (void)run
{
    self.isRunning = YES;
    self.rendererView.shouldMakeThumbnail = YES;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        Runner *runner = [[Runner alloc] initWithNodes:self.nodes];
        runner.delegate = self;
        self.rendererView.renderer = runner.renderer;
        while (!runner.isFinished && self.isRunning)
        {
            [runner runCommand];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)runnerLog:(NSString *)message
{
    NSLog(@"%@", message);
}

- (void)updateRendererView
{
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
