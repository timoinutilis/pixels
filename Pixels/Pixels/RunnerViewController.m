//
//  RunnerViewController.m
//  Pixels
//
//  Created by Timo Kloss on 30/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "RunnerViewController.h"
#import "Runner.h"

@interface RunnerViewController ()

@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property BOOL isRunning;

@end

@implementation RunnerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.logTextView.text = @"";
}

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
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        Runner *runner = [[Runner alloc] initWithNodes:self.nodes];
        runner.delegate = self;
        while (!runner.isFinished && self.isRunning)
        {
            [runner runCommand];
        }
    });
}

- (IBAction)onExitTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)runnerLog:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logTextView.text = [NSString stringWithFormat:@"%@%@\n", self.logTextView.text, message];
    });
}

@end
