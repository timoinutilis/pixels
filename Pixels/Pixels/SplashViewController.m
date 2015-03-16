//
//  SplashViewController.m
//  Pixels
//
//  Created by Timo Kloss on 16/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "SplashViewController.h"

@interface SplashViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@end

@implementation SplashViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.5 delay:0.3 options:0 animations:^{
        
        self.logoImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
        
    } completion:^(BOOL finished) {
        
        [self showApp];
        
    }];
}

- (void)showApp
{
    UIView *splashView = self.view;

    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AppStart"];
    [UIApplication sharedApplication].keyWindow.rootViewController = vc;
    [vc.view addSubview:splashView];
    
    [UIView animateWithDuration:0.3 animations:^{
        
        splashView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        [splashView removeFromSuperview];
        
    }];
}

@end
