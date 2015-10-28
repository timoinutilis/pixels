//
//  SplashViewController.m
//  Pixels
//
//  Created by Timo Kloss on 16/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "SplashViewController.h"
#import "AudioPlayer.h"

@interface SplashViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@property BOOL animationDone;
@property BOOL timerDone;
@property AudioPlayer *audioPlayer;

@end

@implementation SplashViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIWindow* window = [UIApplication sharedApplication].windows.firstObject;
    
    self.label.transform = CGAffineTransformMakeTranslation(0, window.frame.size.height * -0.5f - 35.0f - 12.0f);
    self.logoImageView.transform = CGAffineTransformMakeTranslation(0, 20);
    self.logoImageView.alpha = 0.0f;
    
    self.audioPlayer = [[AudioPlayer alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(onTimerComplete:) userInfo:nil repeats:NO];
    [self.audioPlayer start];
    
    [UIView animateWithDuration:1 delay:0.3 options:UIViewAnimationOptionCurveLinear animations:^{
        
        self.label.transform = CGAffineTransformMakeTranslation(0, 0);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{

            self.logoImageView.transform = CGAffineTransformMakeTranslation(0, 0);
            self.logoImageView.alpha = 1.0f;
            [self playSound];
            
        } completion:^(BOOL finished) {
            
            self.animationDone = YES;
            [self checkComplete];
        }];
        
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)playSound
{
    SoundNote *note;
    
    note = [self.audioPlayer nextNoteForVoice:0];
    note->pitch = 52;
    note->duration = 6;
    
    note = [self.audioPlayer nextNoteForVoice:0];
    note->pitch = 50;
    note->duration = 6;
    
    note = [self.audioPlayer nextNoteForVoice:1];
    note->pitch = 48;
    note->duration = 6;

    note = [self.audioPlayer nextNoteForVoice:1];
    note->pitch = 46;
    note->duration = 6;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.audioPlayer stop];
}

- (void)onTimerComplete:(id)sender
{
    self.timerDone = YES;
    [self checkComplete];
}

- (void)checkComplete
{
    if (self.animationDone && self.timerDone)
    {
        [self showApp];
    }
}

- (void)showApp
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AppStart"];
    id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = vc;
    
    [UIView transitionWithView:appDelegate.window duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        appDelegate.window.rootViewController = vc;
    } completion:nil];
}

@end
