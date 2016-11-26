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
#import "UITableView+Parse.h"

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagPost,
    CellTagFollowers,
    CellTagFollowing
};

static NSString *const SectionInfo = @"Info";
static NSString *const SectionPostStatus = @"PostStatus";
static NSString *const SectionPosts = @"Posts";

static const NSInteger LIMIT = 50;

@interface CommDetailViewController ()

@property LCCUser *user;
@property CommListMode mode;

@property NSMutableArray *posts;
@property NSMutableDictionary *usersById;
@property NSMutableDictionary *statsById;

@property NSArray *sections;
@property CommProfileCell *profileCell;
@property CommWriteStatusCell *writeStatusCell;
@property ExtendedActivityIndicatorView *activityIndicator;
@property BOOL userNeedsUpdate;
@property LCCPostCategory filterCategory;
@property int currentOffset;
@property NSString *currentRoute;
@property BOOL hasMorePosts;
@property BOOL isLoading;

@end

@implementation CommDetailViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _activityIndicator = [[ExtendedActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatsChanged:) name:PostStatsChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostStatsChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.mode == CommListModeUndefined)
    {
        LCCUser *user = [CommunityModel sharedInstance].currentUser;
        [self setUser:user mode:CommListModeNews];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)setUser:(LCCUser *)user mode:(CommListMode)mode
{
    if ([user isMe])
    {
        // use global instance of user
        self.user = [CommunityModel sharedInstance].currentUser;
    }
    else
    {
        self.user = user;
    }
    self.mode = mode;
    
    [self updateDataForceReload:NO];
}

- (IBAction)onRefreshPulled:(id)sender
{
    [self updateDataForceReload:YES];
}

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onFollowsChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeNews)
    {
        [self updateDataForceReload:NO];
    }
    else if (self.mode == CommListModeProfile)
    {
        self.userNeedsUpdate = YES;
        [self.tableView reloadData];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeNews)
    {
        self.user = [CommunityModel sharedInstance].currentUser;
        [self updateDataForceReload:NO];
    }
    else if (self.mode == CommListModeProfile)
    {
        if ([self.user isMe])
        {
            self.userNeedsUpdate = YES;
            [self.tableView reloadData];
        }
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
            || [post.sharedPost isEqualToString:deletedPostId])
        {
            [self.posts removeObjectAtIndex:i];
            changed = YES;
            break;
        }
    }
    if (changed)
    {
        [self.tableView reloadData];
    }
}

- (void)onStatsChanged:(NSNotification *)notification
{
    LCCPostStats *stats = notification.userInfo[@"stats"];
    self.statsById[stats.objectId] = stats;
    [self updateVisiblePosts];
}

- (void)updateDataForceReload:(BOOL)forceReload
{
    switch (self.mode)
    {
        case CommListModeNews: {
            self.title = @"News";
            self.sections = @[SectionInfo, SectionPosts];
            self.currentOffset = 0;
            self.currentRoute = [NSString stringWithFormat:@"users/%@/news", (self.user ? self.user.objectId : @"guest")];
            [self loadCurrentQueryForceReload:forceReload];
            break;
        }
        case CommListModeProfile: {
            self.title = self.user.username;
            self.sections = [self.user isMe] ? @[SectionInfo, SectionPostStatus, SectionPosts] : @[SectionInfo, SectionPosts];
            self.currentOffset = 0;
            self.currentRoute = [NSString stringWithFormat:@"users/%@", self.user.objectId];
            [self loadCurrentQueryForceReload:forceReload];
            break;
        }
        case CommListModeUndefined:
            break;
    }
}

- (void)loadCurrentQueryForceReload:(BOOL)forceReload
{
    self.isLoading = YES;
    BOOL add = (self.currentOffset > 0);
    NSArray *oldPosts = self.posts.copy;
    [self.activityIndicator increaseActivity];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"offset"] = @(self.currentOffset);
    params[@"limit"] = @(LIMIT);
    if (self.filterCategory != LCCPostCategoryUndefined)
    {
        params[@"category"] = @(self.filterCategory);
    }

    [[CommunityModel sharedInstance].sessionManager GET:self.currentRoute parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

        [self.activityIndicator decreaseActivity];
        
        id userDict = responseObject[@"user"];
        if (self.mode == CommListModeProfile && userDict)
        {
            [self.user updateWithDictionary:userDict];
            self.userNeedsUpdate = YES;
        }
        
        NSArray *posts = [LCCPost objectsFromArray:responseObject[@"posts"]];
        NSDictionary *usersById = [LCCUser objectsByIdFromArray:responseObject[@"users"]];
        NSDictionary *statsById = [LCCPostStats objectsByIdFromArray:responseObject[@"postStats"]];
        if (add)
        {
            [self.posts addObjectsFromArray:posts];
            [self.usersById addEntriesFromDictionary:usersById];
            [self.statsById addEntriesFromDictionary:statsById];
        }
        else
        {
            self.posts = posts.mutableCopy;
            self.usersById = usersById.mutableCopy;
            self.statsById = statsById.mutableCopy;
        }
        
        if (self.mode == CommListModeNews)
        {
            self.posts = [self filteredNewsWithPosts:self.posts];
        }
        
        self.hasMorePosts = (posts.count == LIMIT);
        self.currentOffset += LIMIT; // for next load
        if (self.mode == CommListModeProfile)
        {
            // don't fetch complete user again for following pages
            self.currentRoute = [NSString stringWithFormat:@"users/%@/posts", self.user.objectId];
        }
        if (forceReload && !add)
        {
            [self updateVisiblePosts];
            [self.tableView reloadDataAnimatedWithOldArray:oldPosts newArray:self.posts inSection:self.sections.count - 1 offset:1];
        }
        else
        {
            [self.tableView reloadData];
        }
        
        [self.refreshControl endRefreshing];
        self.isLoading = NO;

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        [self.activityIndicator decreaseActivity];
        [self showAlertWithTitle:@"Could not load posts" message:error.presentableError.localizedDescription block:nil];
        [self.refreshControl endRefreshing];
        self.isLoading = NO;

    }];
}

- (void)updateVisiblePosts
{
    NSArray *cells = self.tableView.visibleCells;
    for (CommPostCell *cell in cells)
    {
        if ([cell isKindOfClass:[CommPostCell class]])
        {
            for (LCCPost *post in self.posts)
            {
                if ([post.objectId isEqualToString:cell.post.objectId])
                {
                    LCCPostStats *stats = self.statsById[post.stats];
                    [cell setStats:stats];
                    break;
                }
            }
        }
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
            [sharedPosts addObject:post.sharedPost];
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
    else if (![CommunityModel sharedInstance].currentUser)
    {
        UIViewController *vc = [CommLogInViewController create];
        [self presentInNavigationViewController:vc];
    }
    else if ([[CommunityModel sharedInstance] userInFollowing:self.user])
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
        
        LCCPost *post = [[LCCPost alloc] init];
        post.type = LCCPostTypeStatus;
        post.category = LCCPostCategoryStatus;
        post.title = statusTitleText;
        post.detail = statusDetailText;
        
        [self.activityIndicator increaseActivity];
        
        NSString *route = [NSString stringWithFormat:@"/users/%@/posts", [CommunityModel sharedInstance].currentUser.objectId];
        NSDictionary *params = [post dirtyDictionary];
        
        [[CommunityModel sharedInstance].sessionManager POST:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

            [self.activityIndicator decreaseActivity];
            [post updateWithDictionary:responseObject[@"post"]];
            [post resetDirty];
            
            LCCPostStats *stats = [[LCCPostStats alloc] initWithDictionary:responseObject[@"postStats"]];
            self.statsById[stats.objectId] = stats;
            
//            [PFQuery clearAllCachedResults];
            
            self.writeStatusCell.titleTextField.text = @"";
            self.writeStatusCell.textView.text = @"";
            
            [self.posts insertObject:post atIndex:0];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:2];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [[AppController sharedController] registerForNotifications];
            
            button.enabled = YES;

        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

            [self.activityIndicator decreaseActivity];
            [self showAlertWithTitle:@"Could not send status update." message:error.presentableError.localizedDescription block:nil];
            button.enabled = YES;

        }];
    }
}

- (IBAction)onFilterChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex)
    {
        case 0: self.filterCategory = LCCPostCategoryUndefined; break;
        case 1: self.filterCategory = LCCPostCategoryGame; break;
        case 2: self.filterCategory = LCCPostCategoryTool; break;
        case 3: self.filterCategory = LCCPostCategoryDemo; break;
        case 4: self.filterCategory = LCCPostCategoryStatus; break;
    }
    [self updateDataForceReload:NO];
}

- (void)deletePost:(LCCPost *)post indexPath:(NSIndexPath *)indexPath
{
    [self.activityIndicator increaseActivity];
    self.view.userInteractionEnabled = NO;
 
    NSString *route = [NSString stringWithFormat:@"/posts/%@", post.objectId];
    [[CommunityModel sharedInstance].sessionManager DELETE:route parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [self.activityIndicator decreaseActivity];
        self.view.userInteractionEnabled = YES;
        [self.posts removeObject:post];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//        [PFQuery clearAllCachedResults];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        [self.activityIndicator decreaseActivity];
        self.view.userInteractionEnabled = YES;
        [self showAlertWithTitle:@"Could not delete post." message:error.presentableError.localizedDescription block:nil];
        
    }];
}

#pragma mark - Table view

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionId = self.sections[indexPath.section];
    if (sectionId == SectionInfo && indexPath.row == 0)
    {
        return 122;
    }
    else if (sectionId == SectionPostStatus)
    {
        return 132;
    }
    else if (sectionId == SectionPosts)
    {
        return 84;
    }
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (self.posts != nil ? self.sections.count : 0);
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
        NSInteger num = self.posts.count + 1; // posts + filter
        if (self.hasMorePosts)
        {
            num++; // "Loading more..." cell
        }
        return num;
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
            if ([CommunityModel sharedInstance].currentUser)
            {
                cell.infoTextLabel.text = @"Here you see featured programs, official news, and posts of all the users you follow.";
            }
            else
            {
                cell.infoTextLabel.text = @"Here you see featured programs and official news. Log in to follow more users!";
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
        if (indexPath.row == 0)
        {
            CommFilterCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommFilterCell" forIndexPath:indexPath];
            cell.postCategory = self.filterCategory;
            return cell;
        }
        else if (indexPath.row - 1 == self.posts.count)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingMoreCell" forIndexPath:indexPath];
            return cell;
        }
        else
        {
            LCCPost *post = self.posts[indexPath.row - 1];
            LCCUser *user = self.usersById[post.user];
            LCCPostStats *stats = self.statsById[post.stats];
            NSString *cellType = (post.type == LCCPostTypeStatus || post.image == nil) ? @"StatusCell" : @"ProgramCell";
            CommPostCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType forIndexPath:indexPath];
            [cell setPost:post user:user showName:(self.mode == CommListModeNews)];
            [cell setStats:stats];
            cell.tag = CellTagPost;
            return cell;
        }
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
            LCCPost *post = self.posts[indexPath.row - 1];
            if (post.type == LCCPostTypeShare)
            {
                LCCPost *sharedPost = [[LCCPost alloc] initWithObjectId:post.sharedPost];
                [vc setPost:sharedPost mode:CommPostModePost];
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionId = self.sections[indexPath.section];
    if (sectionId == SectionPosts && indexPath.row > 0)
    {
        LCCUser *user = [CommunityModel sharedInstance].currentUser;
        LCCPost *post = self.posts[indexPath.row - 1];
        
        if ([user isNewsUser] && post.type == LCCPostTypeShare && [post.user isEqualToString:user.objectId])
        {
            return UITableViewCellEditingStyleDelete;
        }
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionId = self.sections[indexPath.section];
    if (sectionId == SectionPosts && indexPath.row > 0)
    {
        LCCPost *post = self.posts[indexPath.row - 1];
        [self deletePost:post indexPath:indexPath];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (   self.hasMorePosts && !self.isLoading
        && scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.bounds.size.height - 80.0)
    {
        [self loadCurrentQueryForceReload:NO];
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
        if ([CommunityModel sharedInstance].currentUser && [[CommunityModel sharedInstance] userInFollowing:user])
        {
            [self.actionButton setTitle:@"Following ✓" forState:UIControlStateNormal];
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

@implementation CommFilterCell

- (void)setPostCategory:(LCCPostCategory)postCategory
{
    switch (postCategory)
    {
        case LCCPostCategoryUndefined:
            self.segmentedControl.selectedSegmentIndex = 0;
            break;
        case LCCPostCategoryGame:
            self.segmentedControl.selectedSegmentIndex = 1;
            break;
        case LCCPostCategoryTool:
            self.segmentedControl.selectedSegmentIndex = 2;
            break;
        case LCCPostCategoryDemo:
            self.segmentedControl.selectedSegmentIndex = 3;
            break;
        case LCCPostCategoryStatus:
            self.segmentedControl.selectedSegmentIndex = 4;
            break;
    }
}

@end

@interface CommPostCell()
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;

@property (nonatomic) LCCPost *post;
@property (nonatomic) LCCUser *user;
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

- (void)setPost:(LCCPost *)post user:(LCCUser *)user showName:(BOOL)showName
{
    _post = post;
    _user = user;
    
    self.starImageView.hidden = ![user isNewsUser];
    
    self.titleLabel.text = post.title;

    NSMutableArray *infos = [NSMutableArray arrayWithCapacity:4];
    if (post.category != LCCPostCategoryStatus)
    {
        [infos addObject:[post categoryString]];
    }
    if (showName)
    {
        NSString *name = (post.type == LCCPostTypeShare) ? [NSString stringWithFormat:@"Shared by %@", user.username] : user.username;
        [infos addObject:name];
    }
    NSString *date = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    [infos addObject:date];
    self.dateLabel.text = [infos componentsJoinedByString:@" - "];
    
    if (self.iconImageView)
    {
        [self.iconImageView sd_setImageWithURL:post.image];
    }
}

- (void)setStats:(LCCPostStats *)stats
{
    if (stats)
    {
        NSString *likesWord = stats.numLikes == 1 ? @"Like" : @"Likes";
        NSString *downloadsWord = stats.numDownloads == 1 ? @"Download" : @"Downloads";
        NSString *commentsWord = stats.numComments == 1 ? @"Comment" : @"Comments";
        
        if (self.post.category == LCCPostCategoryStatus)
        {
            self.statsLabel.text = [NSString stringWithFormat:@"%d %@, %d %@",
                                    stats.numLikes, likesWord,
                                    stats.numComments, commentsWord];
        }
        else
        {
            self.statsLabel.text = [NSString stringWithFormat:@"%d %@, %d %@, %d %@",
                                    stats.numLikes, likesWord,
                                    stats.numDownloads, downloadsWord,
                                    stats.numComments, commentsWord];
        }
    }
    else
    {
        self.statsLabel.text = @" ";
    }
}

@end
