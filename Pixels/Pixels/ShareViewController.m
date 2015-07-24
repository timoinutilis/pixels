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
#import "CommunityModel.h"
#import "CommLogInViewController.h"
#import "UIViewController+LowResCoder.h"
#import "GORCycleManager.h"
#import "Compiler.h"
#import "NSString+Utils.h"

@interface ShareViewController ()

@property ShareHeaderCell *headerCell;
@property ShareTextFieldCell *titleCell;
@property ShareTextViewCell *descriptionCell;
@property ShareActionCell *loginCell;
@property UITableViewCell *categoryGameCell;
@property UITableViewCell *categoryToolCell;
@property UITableViewCell *categoryDemoCell;

@property (nonatomic) LCCPostCategory selectedCategory;
@property GORCycleManager *cycleManager;

@property (nonatomic) IBOutlet UIBarButtonItem *sendItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelItem;

@end

@implementation ShareViewController

+ (UIViewController *)createShareWithDelegate:(id <ShareViewControllerDelegate>)delegate project:(Project *)project
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ShareViewController *vc = (ShareViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ShareView"];
    vc.shareDelegate = delegate;
    vc.project = project;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = vc.modalPresentationStyle;
    nav.modalTransitionStyle = vc.modalTransitionStyle;
    return nav;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareHeaderCell"];
    self.headerCell.iconImageView.image = (self.project.iconData) ? [UIImage imageWithData:self.project.iconData] : [UIImage imageNamed:@"icon_project"];
    [self addCell:self.headerCell];
    
    self.loginCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareActionCell"];
    [self addCell:self.loginCell];

    [self setHeaderTitle:@"Program Title" section:1];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextFieldCell"];
    self.titleCell.textField.placeholder = @"Title";
    self.titleCell.textField.text = self.project.name;
    [self addCell:self.titleCell];

    [self setHeaderTitle:@"Category" section:2];
    
    self.categoryGameCell = [self.tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
    self.categoryGameCell.textLabel.text = @"Game (or demo of game)";
    [self addCell:self.categoryGameCell];
    
    self.categoryToolCell = [self.tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
    self.categoryToolCell.textLabel.text = @"Tool";
    [self addCell:self.categoryToolCell];
    
    self.categoryDemoCell = [self.tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
    self.categoryDemoCell.textLabel.text = @"Demo (Gfx/SFX examples)";
    [self addCell:self.categoryDemoCell];
    
    [self setHeaderTitle:@"Write a Description" section:3];
    
    self.descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextViewCell"];
    [self addCell:self.descriptionCell];
    
    [self updateLogin:nil];
    
    self.selectedCategory = LCCPostCategoryUndefined;
    
    self.cycleManager = [[GORCycleManager alloc] initWithFields:@[self.titleCell.textField, self.descriptionCell.textView]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLogin:) name:CurrentUserChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.project.iconData)
    {
        [self showAlertWithTitle:@"This program doesn't have an icon yet." message:@"Please start it once to create one!" block:^{
            [self onCancelTapped:nil];
        }];
    }
    else
    {
        NSError *error;
        [Compiler compileSourceCode:self.project.sourceCode error:&error];
        if (error)
        {
            [self showAlertWithTitle:@"This program has errors." message:@"Please fix them before posting!" block:^{
                [self onCancelTapped:nil];
            }];
        }
    }
}

- (void)setSelectedCategory:(LCCPostCategory)selectedCategory
{
    _selectedCategory = selectedCategory;
    self.categoryGameCell.accessoryType = (selectedCategory == LCCPostCategoryGame) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.categoryToolCell.accessoryType = (selectedCategory == LCCPostCategoryTool) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.categoryDemoCell.accessoryType = (selectedCategory == LCCPostCategoryDemo) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)updateLogin:(NSNotification *)notification
{
    LCCUser *user = (LCCUser *)[PFUser currentUser];
    if (user)
    {
        self.loginCell.textLabel.text = [NSString stringWithFormat:@"%@ (Tap to log out)", user.username];
    }
    else
    {
        self.loginCell.textLabel.text = @"Log in / Register";
    }
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.view endEditing:YES];
    [self.shareDelegate onClosedWithSuccess:NO];
}

- (IBAction)onSendTapped:(id)sender
{
    [self.view endEditing:YES];
    
    if (![PFUser currentUser])
    {
        CommLogInViewController *vc = [CommLogInViewController create];
        [self presentInNavigationViewController:vc];
    }
    else if (self.selectedCategory == LCCPostCategoryUndefined)
    {
        [self showAlertWithTitle:@"Please selecte a category!" message:nil block:nil];
    }
    else if (self.titleCell.textField.text.length == 0 || self.descriptionCell.textView.text.length == 0)
    {
        [self showAlertWithTitle:@"Please fill out all required fields!" message:nil block:nil];
    }
    else
    {
        [self send];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.loginCell)
    {
        if ([PFUser currentUser])
        {
            [PFUser logOutInBackgroundWithBlock:^(NSError *error) {
                [[CommunityModel sharedInstance] onLoggedOut];
            }];
        }
        else
        {
            CommLogInViewController *vc = [CommLogInViewController create];
            [self presentInNavigationViewController:vc];
        }
    }
    else if (cell == self.categoryGameCell)
    {
        self.selectedCategory = LCCPostCategoryGame;
    }
    else if (cell == self.categoryToolCell)
    {
        self.selectedCategory = LCCPostCategoryTool;
    }
    else if (cell == self.categoryDemoCell)
    {
        self.selectedCategory = LCCPostCategoryDemo;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)send
{
    [self isBusy:YES];

    NSString *title = self.titleCell.textField.text;
    NSString *description = self.descriptionCell.textView.text;
    
    NSString *fileTitle = [title stringByReplacingOccurrencesOfString:@"[^a-zA-Z_0-9]+" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, title.length)];
    if (fileTitle.length > 30)
    {
        fileTitle = [fileTitle substringToIndex:30];
    }
    
    // icon image
    
    NSString *iconFileName = [NSString stringWithFormat:@"%@.png", fileTitle];
    PFFile *imageFile = [PFFile fileWithName:iconFileName data:self.project.iconData];

    // source code
    
    NSString *programFileName = [NSString stringWithFormat:@"%@.txt", fileTitle];
    NSData *fileData = [self.project.sourceCode dataUsingEncoding:NSUTF8StringEncoding];
    PFFile *programFile = [PFFile fileWithName:programFileName data:fileData contentType:@"text/plain"];
    
    // note for users with old app version
    
    LCCProgram *program = [LCCProgram object];
    program.sourceCode = @"REM ************************\nREM PLEASE UPDATE LOWRES CODER AND GET THIS PROGRAM AGAIN\nREM ************************";
    
    // post
    
    LCCPost *post = [LCCPost object];
    post.type = LCCPostTypeProgram;
    post.user = (LCCUser *)[PFUser currentUser];
    post.title = title;
    post.detail = description;
    post.program = program;
    post.programFile = programFile;
    post.image = imageFile;
    post.category = self.selectedCategory;
    post.stats = [LCCPostStats object];
    
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded)
        {
            [[CommunityModel sharedInstance] onPostedWithDate:post.createdAt];
            self.project.postId = post.objectId;
            [self.shareDelegate onClosedWithSuccess:YES];
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
    [self showAlertWithTitle:@"Could not send program" message:@"Please try again later!" block:nil];
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
    self.headerLabel.text = @"Post this program to your community profile! If we like it, we will feature it in the LowRes Coder news!";
    CALayer *layer = self.iconImageView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 6;
    layer.borderWidth = 0.5;
    layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;

}

@end

@implementation ShareTextFieldCell

@end

@implementation ShareActionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textLabel.textColor = self.contentView.tintColor;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.textLabel.textColor = self.contentView.tintColor;
}

@end

@implementation ShareTextViewCell

@end
