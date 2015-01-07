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
#import "GORTextView.h"
#import "GORSeparatorView.h"

@interface ShareViewController ()
@property ShareHeaderCell *headerCell;
@property TextFieldCell *titleCell;
@property TextFieldCell *authorCell;
@property (weak, nonatomic) IBOutlet UILabel *descriptionPlaceholderLabel;
@property (weak, nonatomic) IBOutlet GORTextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet GORSeparatorView *separator2View;
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
    
    self.headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
    if (self.project.iconData)
    {
        self.headerCell.iconImageView.image = [UIImage imageWithData:self.project.iconData];
    }
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.titleCell.label.text = @"Title:";
    self.titleCell.textField.text = self.project.name;
    self.titleCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.titleCell.separatorView.separatorColor = self.tableView.separatorColor;
    
    self.authorCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.authorCell.label.text = @"Author:";
    self.authorCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.authorCell.separatorView.separatorColor = self.tableView.separatorColor;
    
    [self addCell:self.headerCell];
    [self addCell:self.titleCell];
    [self addCell:self.authorCell];
    
    self.descriptionTextView.placeholderView = self.descriptionPlaceholderLabel;
    self.descriptionTextView.hidePlaceholderWhenFirstResponder = YES;
    
    self.separator2View.separatorColor = self.tableView.separatorColor;
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.view endEditing:YES];
    [self.shareDelegate onClosedWithSuccess:NO];
}

- (IBAction)onSendTapped:(id)sender
{
    [self.view endEditing:YES];
    
    if (self.titleCell.textField.text.length == 0 || self.authorCell.textField.text.length == 0 || self.descriptionTextView.text.length == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please fill out all fields!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self send];
    }
}

- (void)send
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"secret": @"916486295",
                                 @"author": self.authorCell.textField.text,
                                 @"title": self.titleCell.textField.text,
                                 @"description": self.descriptionTextView.text,
                                 @"source_code": self.project.sourceCode};
    
    [manager POST:@"http://apps.timokloss.com/tools/pixelsshare.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *response = responseObject;
        if (response[@"error"])
        {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:response[@"error"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [self.shareDelegate onClosedWithSuccess:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Could not send program. Please try later!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
        NSLog(@"error: %@", error);
        
    }];
}

@end

@implementation ShareHeaderCell

- (void)layoutSubviews
{
    CGFloat availableLabelWidth = self.frame.size.width - 80 - 30; //HACK
    self.headerLabel.preferredMaxLayoutWidth = availableLabelWidth;
    [super layoutSubviews];
}

@end

@implementation TextFieldCell

@end
