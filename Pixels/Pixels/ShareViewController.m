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
@property TextFieldCell *mailCell;
@property (nonatomic) IBOutlet UIBarButtonItem *sendItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelItem;
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
    self.headerCell.iconImageView.image = (self.project.iconData) ? [UIImage imageWithData:self.project.iconData] : [UIImage imageNamed:@"icon_project"];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.titleCell.label.text = @"Title:";
    self.titleCell.textField.text = self.project.name;
    self.titleCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.titleCell.separatorView.separatorColor = self.tableView.separatorColor;
    
    self.authorCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.authorCell.label.text = @"Author:";
    self.authorCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.authorCell.separatorView.separatorColor = self.tableView.separatorColor;

    self.mailCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.mailCell.label.text = @"E-Mail:";
    self.mailCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.mailCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
    self.mailCell.textField.placeholder = @"Optional, will not be published";
    self.mailCell.separatorView.separatorColor = self.tableView.separatorColor;
    
    [self addCell:self.headerCell];
    [self addCell:self.titleCell];
    [self addCell:self.authorCell];
    [self addCell:self.mailCell];
    
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
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please fill out all required fields!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self send];
    }
}

- (IBAction)onWebsiteTapped:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lowres.inutilis.com"]];
}

- (void)send
{
    [self isBusy:YES];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"secret": @"916486295",
                                 @"author": self.authorCell.textField.text,
                                 @"mail": self.mailCell.textField.text,
                                 @"title": self.titleCell.textField.text,
                                 @"description": self.descriptionTextView.text,
                                 @"source_code": self.project.sourceCode};
    
    [manager POST:@"http://apps.timokloss.com/tools/pixelsshare.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *response = responseObject;
        if (response[@"error"])
        {
            [self isBusy:NO];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:response[@"error"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            alert.view.tintColor = self.view.tintColor;
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [self.shareDelegate onClosedWithSuccess:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [self isBusy:NO];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Could not send program. Please try later!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = self.view.tintColor;
        [self presentViewController:alert animated:YES completion:nil];
        
        NSLog(@"error: %@", error);
        
    }];
}

- (void)isBusy:(BOOL)isBusy
{
    self.cancelItem.enabled = !isBusy;
    if (isBusy)
    {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityView.frame = CGRectMake(0, 0, 44, 44);
        [activityView startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = self.sendItem;
    }
}

@end

@implementation ShareHeaderCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    CALayer *imageLayer = self.iconImageView.layer;
    imageLayer.cornerRadius = 20;
    imageLayer.masksToBounds = YES;
}

- (void)layoutSubviews
{
    CGFloat availableLabelWidth = self.frame.size.width - 80 - 30; //HACK
    self.headerLabel.preferredMaxLayoutWidth = availableLabelWidth;
    [super layoutSubviews];
}

@end

@implementation TextFieldCell

@end
