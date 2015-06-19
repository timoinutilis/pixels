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
#import "AppStyle.h"

@interface CommSourceCodeViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation CommSourceCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [AppStyle editorColor];
    self.textView.backgroundColor = [AppStyle editorColor];
    self.textView.textColor = [AppStyle tintColor];
    self.textView.tintColor = [AppStyle brightColor];
    self.textView.indicatorStyle = UIScrollViewIndicatorStyleWhite;

    self.textView.text = self.post.program.sourceCode;
}

- (IBAction)onGetTapped:(id)sender
{
    [self addProgramOfPost:self.post];
}

@end
