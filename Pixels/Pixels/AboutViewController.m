//
//  AboutViewController.m
//  Pixels
//
//  Created by Timo Kloss on 16/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"Version %@", version];

}

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
