//
//  CommunityListViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommDetailViewController.h"
#import "CommunityModel.h"
#import "CommPostViewController.h"
#import "UIImageView+WebCache.h"
#import "CommUsersViewController.h"
#import "CommEditUserViewController.h"
#import "UIViewController+LowResCoder.h"

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagPost,
    CellTagFollowers,
    CellTagFollowing
};

static NSString *const SectionInfo = @"Info";
static NSString *const SectionPostStatus = @"PostStatus";
static NSString *const SectionPosts = @"Posts";

@interface CommDetailViewController ()

@property LCCUser *user;
@property CommListMode mode;
@property NSMutableArray *posts;
@property NSArray *sections;
@property CommWriteStatusCell *writeStatusCell;

@end

@implementation CommDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44;
    
    self.writeStatusCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommWriteStatusCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.mode == CommListModeUndefined)
    {
        LCCUser *user = (LCCUser *)[PFUser currentUser];
        [self setUser:user mode:CommListModeNews];
    }
}

- (void)setUser:(LCCUser *)user mode:(CommListMode)mode
{
    if ([user isMe])
    {
        // use global instance of user
        self.user = (LCCUser *)[PFUser currentUser];
    }
    else
    {
        self.user = user;
    }
    self.mode = mode;
    
    [self updateData];
}

- (void)onFollowsChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeNews)
    {
        [self updateData];
    }
    else if (self.mode == CommListModeProfile)
    {
        [self.tableView reloadData];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeProfile && [self.user isMe])
    {
        [self.tableView reloadData];
    }
}

- (void)updateData
{
    switch (self.mode)
    {
        case CommListModeNews: {
            self.title = @"News";
            self.sections = @[SectionInfo, SectionPosts];
            
            NSArray *followedUsers = [[CommunityModel sharedInstance] arrayWithFollowedUsers];
            if (followedUsers.count > 0)
            {
                PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
                [query whereKey:@"user" containedIn:followedUsers];
                [query includeKey:@"sharedPost"];
                [query includeKey:@"user"];
                [query orderByDescending:@"createdAt"];
                query.cachePolicy = kPFCachePolicyNetworkElseCache;
                
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (objects)
                    {
                        self.posts = [NSMutableArray arrayWithArray:objects];
                        [self.tableView reloadData];
                    }
                    else if (error)
                    {
                        NSLog(@"Error: %@", error.description);
                    }
                }];
            }
            else
            {
                self.posts = nil;
                [self.tableView reloadData];
            }
            break;
        }
        case CommListModeProfile: {
            self.title = self.user.username;
//            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.user.username style:UIBarButtonItemStylePlain target:nil action:nil];
            self.sections = [self.user isMe] ? @[SectionInfo, SectionPostStatus, SectionPosts] : @[SectionInfo, SectionPosts];
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
            [query whereKey:@"user" equalTo:self.user];
            [query includeKey:@"sharedPost"];
            [query includeKey:@"user"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (objects)
                {
                    self.posts = [NSMutableArray arrayWithArray:objects];
                    [self.tableView reloadData];
                }
                else if (error)
                {
                    NSLog(@"Error: %@", error.description);
                }
            }];
            break;
        }
        case CommListModeUndefined:
            break;
    }
}

- (IBAction)onActionTapped:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if ([self.user isMe])
    {
        // Edit
        UIViewController *vc = [CommEditUserViewController create];
        [self presentInNavigationViewController:vc];
    }
    else if ([[CommunityModel sharedInstance] followWithUser:self.user])
    {
        button.enabled = NO;
        [[CommunityModel sharedInstance] unfollowUser:self.user];
    }
    else
    {
        button.enabled = NO;
        [[CommunityModel sharedInstance] followUser:self.user];
    }
}

- (IBAction)onSendStatusTapped:(id)sender
{
    if (self.writeStatusCell.titleTextField.text.length > 0)
    {
        [self.view endEditing:YES];
        
        LCCPost *post = [LCCPost object];
        post.user = (LCCUser *)[PFUser currentUser];
        post.type = LCCPostTypeStatus;
        post.category = LCCPostCategoryStatus;
        post.title = self.writeStatusCell.titleTextField.text;
        post.detail = self.writeStatusCell.textView.text;
        
        [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            if (succeeded)
            {
                [self.posts insertObject:post atIndex:0];
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
                self.writeStatusCell.titleTextField.text = @"";
                self.writeStatusCell.textView.text = @"";
            }
            else
            {
                [self showAlertWithTitle:@"Could not send status update" message:@"Please try again later!" block:nil];
            }
            
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionId = self.sections[section];
    if (sectionId == SectionInfo)
    {
        if (self.mode == CommListModeProfile)
        {
            return 3;
        }
        else if (self.mode == CommListModeNews)
        {
            return 1;
        }
    }
    else if (sectionId == SectionPostStatus)
    {
        return 1;
    }
    else if (sectionId == SectionPosts)
    {
        return self.posts.count;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionId = self.sections[section];
    if (sectionId == SectionInfo)
    {
        return (self.mode == CommListModeNews) ? @"Info" : @"User";
    }
    else if (sectionId == SectionPostStatus)
    {
        return @"Write a Status Update";
    }
    else if (sectionId == SectionPosts)
    {
        return @"Posts";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionId = self.sections[indexPath.section];
    if (sectionId == SectionInfo)
    {
        if (self.mode == CommListModeProfile)
        {
            if (indexPath.row == 0)
            {
                CommProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommProfileCell" forIndexPath:indexPath];
                cell.user = self.user;
                return cell;
            }
            else
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailMenuCell" forIndexPath:indexPath];
                if (indexPath.row == 1)
                {
                    cell.textLabel.text = @"Followers";
                    cell.tag = CellTagFollowers;
                }
                else if (indexPath.row == 2)
                {
                    cell.textLabel.text = @"Following";
                    cell.tag = CellTagFollowing;
                }
                return cell;
            }
        }
        else if (self.mode == CommListModeNews)
        {
            CommInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommInfoCell" forIndexPath:indexPath];
            if ([PFUser currentUser])
            {
                cell.infoTextLabel.text = @"Here you see the posts of all the users you follow.";
            }
            else
            {
                cell.infoTextLabel.text = @"Here you see official news and featured programs. Log in to follow more users!";
            }
            return cell;
        }
    }
    else if (sectionId == SectionPostStatus)
    {
        return self.writeStatusCell;
    }
    else if (sectionId == SectionPosts)
    {
        LCCPost *post = self.posts[indexPath.row];
        CommPostCell *cell = [tableView dequeueReusableCellWithIdentifier:(post.type == LCCPostTypeStatus) ? @"StatusCell" : @"ProgramCell" forIndexPath:indexPath];
        cell.post = post;
        cell.tag = CellTagPost;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag)
    {
        case CellTagFollowers: {
            CommUsersViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommUsersView"];
            [vc setUser:self.user mode:CommUsersModeFollowers];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case CellTagFollowing: {
            CommUsersViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommUsersView"];
            [vc setUser:self.user mode:CommUsersModeFollowing];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case CellTagPost: {
            CommPostViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommPostView"];
            LCCPost *post = self.posts[indexPath.row];
            if (post.type == LCCPostTypeShare)
            {
                [vc setPost:post.sharedPost mode:CommPostModePost];
            }
            else
            {
                [vc setPost:post mode:CommPostModePost];
            }
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

@end


@interface CommProfileCell()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *profileDetailLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@end

@implementation CommProfileCell

- (void)setUser:(LCCUser *)user
{
    _user = user;
    self.titleLabel.text = user.username;
    if (user.about.length > 0)
    {
        self.profileDetailLabel.text = user.about;
        self.profileDetailLabel.alpha = 1.0;
    }
    else
    {
        self.profileDetailLabel.text = @"No about text written yet";
        self.profileDetailLabel.alpha = 0.5;
    }
    if ([self.user isMe])
    {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
        [self.actionButton setTitle:@"Edit" forState:UIControlStateNormal];
    }
    else if ([[CommunityModel sharedInstance] canFollowOrUnfollow:user])
    {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
        if ([[CommunityModel sharedInstance] followWithUser:user])
        {
            [self.actionButton setTitle:@"Stop Following" forState:UIControlStateNormal];
        }
        else
        {
            [self.actionButton setTitle:@"Follow" forState:UIControlStateNormal];
        }
    }
    else
    {
        self.actionButton.hidden = YES;
    }
}

@end


@implementation CommInfoCell
@end

@implementation CommWriteStatusCell
@end

@interface CommPostCell()
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@end

@implementation CommPostCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    CALayer *layer = self.iconImageView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 3;
    layer.borderWidth = 0.5;
    layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
}

- (void)setPost:(LCCPost *)post
{
    _post = post;
    
    self.titleLabel.text = post.title;
    self.titleLabel.textColor = [post.user isNewsUser] ? [UIColor redColor] : [UIColor darkTextColor];
    NSString *date = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    NSString *name = (post.type == LCCPostTypeShare) ? [NSString stringWithFormat:@"Shared by %@", post.user.username] : post.user.username;
    if (post.category != LCCPostCategoryStatus)
    {
        self.dateLabel.text = [NSString stringWithFormat:@"%@ - %@ - %@", [post categoryString], name, date];
    }
    else
    {
        self.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", name, date];
    }
    
    if (self.iconImageView)
    {
        [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:post.image.url]];
    }
}

@end
