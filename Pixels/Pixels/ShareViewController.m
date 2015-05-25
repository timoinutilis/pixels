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
#import "AppStyle.h"
#import "CommunityModel.h"

@interface ShareViewController ()
@property ShareHeaderCell *headerCell;
@property TextFieldCell *titleCell;
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
    
    [AppStyle styleNavigationController:self.navigationController];
    self.view.backgroundColor = [AppStyle brightColor];
    self.descriptionTextView.textColor = [AppStyle darkColor];
    self.tableView.separatorColor = [AppStyle barColor];
    
    self.tableView.estimatedRowHeight = 44.0;
    
    self.headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
    self.headerCell.iconImageView.image = (self.project.iconData) ? [UIImage imageWithData:self.project.iconData] : [UIImage imageNamed:@"icon_project"];
    self.headerCell.backgroundColor = [UIColor clearColor];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    self.titleCell.label.text = @"Title:";
    self.titleCell.textField.text = self.project.name;
    self.titleCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.titleCell.separatorView.separatorColor = self.tableView.separatorColor;
    self.titleCell.backgroundColor = [UIColor clearColor];
    
    [self addCell:self.headerCell];
    [self addCell:self.titleCell];
    
    self.descriptionTextView.placeholderView = self.descriptionPlaceholderLabel;
    self.descriptionTextView.hidePlaceholderWhenFirstResponder = YES;
    self.descriptionPlaceholderLabel.textColor = [AppStyle barColor];
    
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
    
    if (self.titleCell.textField.text.length == 0 || self.descriptionTextView.text.length == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please fill out all required fields!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        alert.view.tintColor = [AppStyle alertTintColor];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self send];
    }
}

- (void)send
{
    [self isBusy:YES];
    
    // save image

    PFFile *imageFile = [PFFile fileWithName:@"image.png" data:self.project.iconData];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded)
        {
            // save post

            LCCPost *post = [LCCPost object];
            post.type = LCCPostTypeProgram;
            post.user = (LCCUser *)[PFUser currentUser];
            post.title = self.titleCell.textField.text;
            post.detail = self.descriptionTextView.text;
            post.data = self.project.sourceCode;
            post.image = imageFile;
            
            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                if (succeeded)
                {
                    [[CommunityModel sharedInstance] onPostedWithDate:post.createdAt];
                    [self.shareDelegate onClosedWithSuccess:YES];
                }
                else
                {
                    [self showSendError];
                }
                
            }];
        }
        else
        {
            [self showSendError];
        }
        
    }];
    
}

- (void)showSendError
{
    [self isBusy:NO];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Could not send program" message:@"Please try again later!" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    alert.view.tintColor = [AppStyle alertTintColor];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)isBusy:(BOOL)isBusy
{
    self.cancelItem.enabled = !isBusy;
    if (isBusy)
    {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
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
    self.headerLabel.textColor = [AppStyle darkColor];
    self.headerLabel.text = @"Post your program! If we like it, we will feature it in the community news!";
    CALayer *imageLayer = self.iconImageView.layer;
    imageLayer.cornerRadius = 20;
    imageLayer.masksToBounds = YES;
}

@end

@implementation TextFieldCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.label.textColor = [AppStyle barColor];
    self.textField.textColor = [AppStyle darkColor];
}

@end
