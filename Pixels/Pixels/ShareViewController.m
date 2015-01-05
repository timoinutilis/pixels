//
//  ShareViewController.m
//  Pixels
//
//  Created by Timo Kloss on 5/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "ShareViewController.h"
#import "Project.h"
#import "AFNetworking.h"

@interface ShareViewController ()
@property TextFieldCell *titleCell;
@property TextFieldCell *authorCell;
@property TextFieldCell *descriptionCell;
@end

@implementation ShareViewController

+ (UIViewController *)createShareWithDelegate:(id <ShareViewControllerDelegate>)delegate project:(Project *)project
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:@"Share"];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    ShareViewController *shareVC = (ShareViewController *)vc.childViewControllers[0];
    shareVC.shareDelegate = delegate;
    shareVC.project = project;
    
    return vc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.titleCell.label.text = @"Title:";
    self.titleCell.textField.text = self.project.name;
    self.titleCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.authorCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.authorCell.label.text = @"Author:";
    self.authorCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.descriptionCell.label.text = @"Description:";
    self.descriptionCell.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    [self addCell:self.titleCell];
    [self addCell:self.authorCell];
    [self addCell:self.descriptionCell];
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.view endEditing:YES];
    [self.shareDelegate onClosedWithSuccess:NO];
}

- (IBAction)onSendTapped:(id)sender
{
    [self.view endEditing:YES];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"secret": @"916486295",
                                 @"author": self.authorCell.textField.text,
                                 @"title": self.titleCell.textField.text,
                                 @"description": self.descriptionCell.textField.text,
                                 @"source_code": self.project.sourceCode};
    
    [manager POST:@"http://apps.timokloss.com/tools/pixelsshare.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self.shareDelegate onClosedWithSuccess:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Could not send program. Please try later!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];

        NSLog(@"error: %@", error);
        
    }];
}

@end

@implementation TextFieldCell

@end