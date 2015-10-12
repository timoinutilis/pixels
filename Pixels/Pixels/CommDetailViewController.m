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
#import "CommLogInViewController.h"
#import "UIViewController+LowResCoder.h"
#import "UIViewController+CommUtils.h"
#import "ExtendedActivityIndicatorView.h"
#import "AppController.h"
#import "GORCycleManager.h"

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
@property CommProfileCell *profileCell;
@property CommWriteStatusCell *writeStatusCell;
@property ExtendedActivityIndicatorView *activityIndicator;
@property BOOL userNeedsUpdate;
@property BOOL showsUserUpdateActivity;

@end

@implementation CommDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.activityIndicator = [[ExtendedActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    if ([self isModal])
    {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneTapped:)];
        self.navigationItem.rightBarButtonItems = @[doneItem, activityItem];
    }
    else
    {
        self.navigationItem.rightBarButtonItems = @[activityItem];
    }
    
    self.tableView.estimatedRowHeight = 53;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0"))
    {
        // simple workaround for Split View bug, Table View doesn't adjust for Keyboard on iPhone
        if (   self.mode == CommListModeProfile && [self.user isMe] // only me has text input
            && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 252, 0);
        }
    }
    
    self.writeStatusCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommWriteStatusCell"];
    self.profileCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommProfileCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPostDeleted:) name:PostDeleteNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostDeleteNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self onUserUpdate:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserUpdate:) name:UserUpdateNotification object:nil];
    
    if (self.mode == CommListModeUndefined)
    {
        LCCUser *user = (LCCUser *)[PFUser currentUser];
        [self setUser:user mode:CommListModeNews];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UserUpdateNotification object:nil];
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

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onFollowsChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeNews)
    {
        [self updateData];
    }
    else if (self.mode == CommListModeProfile)
    {
        self.userNeedsUpdate = YES;
        [self.tableView reloadData];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeProfile && [self.user isMe])
    {
        self.userNeedsUpdate = YES;
        [self.tableView reloadData];
    }
}

- (void)onPostDeleted:(NSNotification *)notification
{
    NSString *deletedPostId = notification.userInfo[@"postId"];
    BOOL changed = NO;
    for (int i = (int)self.posts.count - 1; i >= 0; i--)
    {
        LCCPost *post = self.posts[i];
        if (   [post.objectId isEqualToString:deletedPostId]
            || [post.sharedPost.objectId isEqualToString:deletedPostId])
        {
            [self.posts removeObjectAtIndex:i];
            changed = YES;
        }
    }
    if (changed)
    {
        [self.tableView reloadData];
    }
}

- (void)onUserUpdate:(NSNotification *)notification
{
    if ([CommunityModel sharedInstance].isUpdatingUser)
    {
        if (!self.showsUserUpdateActivity)
        {
            [self.activityIndicator increaseActivity];
            self.showsUserUpdateActivity = YES;
        }
    }
    else if (self.showsUserUpdateActivity)
    {
        [self.activityIndicator decreaseActivity];
        self.showsUserUpdateActivity = NO;
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
                [query includeKey:@"stats"];
                [query orderByDescending:@"createdAt"];
                query.cachePolicy = kPFCachePolicyNetworkElseCache;
                
                [self.activityIndicator increaseActivity];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    
                    [self.activityIndicator decreaseActivity];
                    if (objects)
                    {
                        self.posts = [self filteredNewsWithPosts:objects];
                        [self.tableView reloadData];
                    }
                    else if (error)
                    {
                        [self showAlertWithTitle:@"Could not load news" message:error.userInfo[@"error"] block:nil];
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
            self.sections = [self.user isMe] ? @[SectionInfo, SectionPostStatus, SectionPosts] : @[SectionInfo, SectionPosts];
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
            [query whereKey:@"user" equalTo:self.user];
            [query includeKey:@"sharedPost"];
            [query includeKey:@"user"];
            [query includeKey:@"stats"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [self.activityIndicator increaseActivity];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                [self.activityIndicator decreaseActivity];
                if (objects)
                {
                    self.posts = [NSMutableArray arrayWithArray:objects];
                    [self.tableView reloadData];
                }
                else if (error)
                {
                    [self showAlertWithTitle:@"Could not load posts" message:error.userInfo[@"error"] block:nil];
                }
                
            }];
            break;
        }
        case CommListModeUndefined:
            break;
    }
}

- (NSMutableArray *)filteredNewsWithPosts:(NSArray *)objects
{
    NSMutableSet *sharedPosts = [NSMutableSet setWithCapacity:objects.count];
    NSMutableArray *filteredPosts = [NSMutableArray arrayWithCapacity:objects.count];
    
    for (LCCPost *post in objects)
    {
        if (post.sharedPost)
        {
            [sharedPosts addObject:post.sharedPost.objectId];
        }
        if (![sharedPosts containsObject:post.objectId])
        {
            [filteredPosts addObject:post];
        }
    }
    
    return filteredPosts;
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
    else if (![PFUser currentUser])
    {
        UIViewController *vc = [CommLogInViewController create];
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

- (IBAction)onMoreTapped:(id)sender
{
    [self.profileCell toggleDetailSize];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (IBAction)onSendStatusTapped:(id)sender
{
    NSString *statusTitleText = [self.writeStatusCell.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *statusDetailText = [self.writeStatusCell.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (statusTitleText.length == 0 || statusDetailText.length == 0)
    {
        [self showAlertWithTitle:@"Please write a title and a detail text!" message:nil block:nil];
    }
    else
    {
        [self.view endEditing:YES];
        
        UIButton *button = (UIButton *)sender;
        button.enabled = NO;
        
        LCCPost *post = [LCCPost object];
        post.user = (LCCUser *)[PFUser currentUser];
        post.type = LCCPostTypeStatus;
        post.category = LCCPostCategoryStatus;
        post.title = statusTitleText;
        post.detail = statusDetailText;
        
        [self.activityIndicator increaseActivity];
        [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            [self.activityIndicator decreaseActivity];
            
            if (succeeded)
            {
                [self.posts insertObject:post atIndex:0];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:2];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                self.writeStatusCell.titleTextField.text = @"";
                self.writeStatusCell.textView.text = @"";
                
                NSDictionary *dimensions = @{@"category": [post categoryString],
                                             @"app": ([AppController sharedController].isFullVersion) ? @"full version" : @"free"};
                [PFAnalytics trackEvent:@"post" dimensions:dimensions];
                
                [[AppController sharedController] registerForNotifications];
            }
            else if (error)
            {
                [self showAlertWithTitle:@"Could not send status update." message:error.userInfo[@"error"] block:nil];
            }
            
            button.enabled = YES;
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
                if (self.profileCell.user != self.user || self.userNeedsUpdate)
                {
                    self.profileCell.user = self.user;
                    self.userNeedsUpdate = NO;
                }
                return self.profileCell;
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
                cell.infoTextLabel.text = @"Here you see official news, featured programs, and posts of all the users you follow.";
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
        NSString *cellType = (post.type == LCCPostTypeStatus) ? @"StatusCell" : @"ProgramCell";
        CommPostCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType forIndexPath:indexPath];
        cell.showName = (self.mode == CommListModeNews);
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
@property (weak, nonatomic) IBOutlet UITextView *detailTextView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailHeightConstraint;
@end

@implementation CommProfileCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.detailTextView.textContainer.lineFragmentPadding = 0;
    self.detailTextView.textContainerInset = UIEdgeInsetsZero;
}

- (void)setUser:(LCCUser *)user
{
    _user = user;
    self.titleLabel.text = user.username;
    if (user.about.length > 0)
    {
        self.detailTextView.text = [user.about stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.detailTextView.alpha = 1.0;
    }
    else
    {
        self.detailTextView.text = @"No about text written yet";
        self.detailTextView.alpha = 0.5;
    }
    
    if ([self.user isMe])
    {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
        [self.actionButton setTitle:@"Edit" forState:UIControlStateNormal];
    }
    else if ([self.user isNewsUser])
    {
        self.actionButton.hidden = YES;
    }
    else
    {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
        if ([PFUser currentUser] && [[CommunityModel sharedInstance] followWithUser:user])
        {
            [self.actionButton setTitle:@"Stop Following" forState:UIControlStateNormal];
        }
        else
        {
            [self.actionButton setTitle:@"Follow" forState:UIControlStateNormal];
        }
    }
    
    [self updateMoreButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.detailTextView.frame.size.height >= self.detailHeightConstraint.constant)
    {
        self.moreButton.hidden = NO;
        [self updateMoreButton];
    }
    else
    {
        self.moreButton.hidden = YES;
    }
}

- (void)toggleDetailSize
{
    if (self.detailHeightConstraint.priority < 999)
    {
        self.detailHeightConstraint.priority = 999;
    }
    else
    {
        self.detailHeightConstraint.priority = 1;
    }
    [self updateMoreButton];
}

- (void)updateMoreButton
{
    if (self.detailHeightConstraint.priority < 999)
    {
        [self.moreButton setTitle:@"Less" forState:UIControlStateNormal];
    }
    else
    {
        [self.moreButton setTitle:@"More..." forState:UIControlStateNormal];
    }
}

@end


@implementation CommInfoCell
@end

@interface CommWriteStatusCell()
@property GORCycleManager *cycleManager;
@end

@implementation CommWriteStatusCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.placeholderView = self.detailPlaceholderLabel;
    self.textView.hidePlaceholderWhenFirstResponder = YES;
    
    self.cycleManager = [[GORCycleManager alloc] initWithFields:@[self.titleTextField, self.textView]];
}

@end

@interface CommPostCell()
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
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
    
    self.starImageView.hidden = ![post.user isNewsUser];
    
    self.titleLabel.text = post.title;

    NSMutableArray *infos = [NSMutableArray arrayWithCapacity:4];
    if (post.category != LCCPostCategoryStatus)
    {
        [infos addObject:[post categoryString]];
    }
    if (self.showName)
    {
        NSString *name = (post.type == LCCPostTypeShare) ? [NSString stringWithFormat:@"Shared by %@", post.user.username] : post.user.username;
        [infos addObject:name];
    }
    NSString *date = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    [infos addObject:date];
    self.dateLabel.text = [infos componentsJoinedByString:@" - "];
    
    if ([post.stats isDataAvailable])
    {
        NSString *likesWord = post.stats.numLikes == 1 ? @"Like" : @"Likes";
        NSString *downloadsWord = post.stats.numDownloads == 1 ? @"Download" : @"Downloads";
        NSString *commentsWord = post.stats.numComments == 1 ? @"Comment" : @"Comments";
        
        if (post.category == LCCPostCategoryStatus)
        {
            self.statsLabel.text = [NSString stringWithFormat:@"%d %@, %d %@",
                                    post.stats.numLikes, likesWord,
                                    post.stats.numComments, commentsWord];
        }
        else
        {
            self.statsLabel.text = [NSString stringWithFormat:@"%d %@, %d %@, %d %@",
                                    post.stats.numLikes, likesWord,
                                    post.stats.numDownloads, downloadsWord,
                                    post.stats.numComments, commentsWord];
        }
    }
    else
    {
        self.statsLabel.text = @" ";
    }
    
    if (self.iconImageView)
    {
        [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:post.image.url]];
    }
}

@end
