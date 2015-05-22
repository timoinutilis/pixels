//
//  CommLogInViewController.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommLogInViewController.h"
#import "CommunityModel.h"

NSString *const UserDefaultsLogInKey = @"UserDefaultsLogIn";

@interface CommLogInViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation CommLogInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    NSString *lastUserName = [storage objectForKey:UserDefaultsLogInKey];
    if (lastUserName)
    {
        self.userNameTextField.text = lastUserName;
    }
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onRegisterTapped:(id)sender
{
    LCCUser *user = (LCCUser *)[PFUser user];
    user.username = self.userNameTextField.text;
    user.password = self.passwordTextField.text;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded)
        {
            [self loggedIn];
        }
        else if (error)
        {
            NSLog(@"error: %@", error.description);
        }
        
    }];
}

- (IBAction)onLogInTapped:(id)sender
{
    [PFUser logInWithUsernameInBackground:self.userNameTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
       
        if (user)
        {
            [self loggedIn];
        }
        else if (error)
        {
            NSLog(@"error: %@", error.description);
        }
        
    }];
}

- (void)loggedIn
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setObject:self.userNameTextField.text forKey:UserDefaultsLogInKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:CurrentUserChangeNotification object:self];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
