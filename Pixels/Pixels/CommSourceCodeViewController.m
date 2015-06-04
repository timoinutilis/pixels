//
//  CommSourceCodeViewController.m
//  Pixels
//
//  Created by Timo Kloss on 22/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommSourceCodeViewController.h"
#import "CommunityModel.h"
#import "UIViewController+CommUtils.h"

@interface CommSourceCodeViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation CommSourceCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.textView.text = self.post.program.sourceCode;
}

- (IBAction)onGetTapped:(id)sender
{
    [self addProgramOfPost:self.post];
}

@end