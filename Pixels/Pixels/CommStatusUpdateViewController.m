//
//  CommStatusUpdateViewController.m
//  Pixels
//
//  Created by Timo Kloss on 26/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "CommStatusUpdateViewController.h"
#import "TextFieldTableViewCell.h"
#import "TextViewTableViewCell.h"
#import "GORCycleManager.h"
#import "CommunityModel.h"
#import "AppController.h"
#import "UIViewController+LowResCoder.h"
#import "AppStyle.h"

@interface CommStatusUpdateViewController ()

@property (nonatomic) IBOutlet UIBarButtonItem *sendItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelItem;

@property TextFieldTableViewCell *titleCell;
@property TextViewTableViewCell *descriptionCell;
@property GORCycleManager *cycleManager;

@property (nonatomic) LCCPostType postType;
@property (nonatomic, copy) CommStatusUpdateBlock block;

@end

@implementation CommStatusUpdateViewController

+ (UIViewController *)createWithStoryboard:(UIStoryboard *)storyboard postType:(LCCPostType)type completion:(CommStatusUpdateBlock)block
{
    CommStatusUpdateViewController *vc = (CommStatusUpdateViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CommStatusUpdateView"];
    vc.block = block;
    vc.postType = type;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = vc.modalPresentationStyle;
    nav.modalTransitionStyle = vc.modalTransitionStyle;
    return nav;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [AppStyle tableBackgroundColor];
    
    [self setHeaderTitle:@"Title" section:0];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextFieldCell"];
    self.titleCell.textField.placeholder = @"Title";
    [self addCell:self.titleCell];
    
    [self setHeaderTitle:@"Write Your Text" section:1];
    
    self.descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextViewCell"];
    [self addCell:self.descriptionCell];
    
    self.cycleManager = [[GORCycleManager alloc] initWithFields:@[self.titleCell.textField, self.descriptionCell.textView]];
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.view endEditing:YES];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSendTapped:(id)sender
{
    [self.view endEditing:YES];
    if (self.titleCell.textField.text.length == 0 || self.descriptionCell.textView.text.length == 0)
    {
        [self showAlertWithTitle:@"Please fill out all fields!" message:nil block:nil];
    }
    else
    {
        [self send];
    }
}

- (void)send
{
    [self isBusy:YES];
    
    NSString *title = self.titleCell.textField.text;
    NSString *description = self.descriptionCell.textView.text;
    
    // post
    LCCPost *post = [[LCCPost alloc] init];
    post.type = self.postType;
    post.title = title;
    post.detail = description;
    post.category = (self.postType == LCCPostTypeStatus) ? LCCPostCategoryStatus : LCCPostCategoryQuestion;
    
    NSString *route = [NSString stringWithFormat:@"/users/%@/posts", [CommunityModel sharedInstance].currentUser.objectId];
    NSDictionary *params = [post dirtyDictionary];
    
    [[CommunityModel sharedInstance].sessionManager POST:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [post updateWithDictionary:responseObject[@"post"]];
        [post resetDirty];
        
        LCCPostStats *stats = [[LCCPostStats alloc] initWithDictionary:responseObject[@"postStats"]];
        
//        [PFQuery clearAllCachedResults];
        
        if (self.block)
        {
            self.block(post, stats);
            self.block = nil;
        }
        
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [[AppController sharedController] registerForNotifications];
        }];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        [self isBusy:NO];
        [[CommunityModel sharedInstance] handleAPIError:error title:@"Could not send text" viewController:self];
        
    }];
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
