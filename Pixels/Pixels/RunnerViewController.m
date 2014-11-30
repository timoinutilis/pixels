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

    Runner *runner = [[Runner alloc] initWithNodes:self.nodes];
    runner.delegate = self;
    while (!runner.isFinished)
    {
        [runner runCommand];
    }
}

- (IBAction)onExitTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)runnerLog:(NSString *)message
{
    self.logTextView.text = [NSString stringWithFormat:@"%@%@\n", self.logTextView.text, message];
}

@end
