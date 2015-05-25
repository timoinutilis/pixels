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

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagFollowers,
    CellTagFollowing
};

@interface CommDetailViewController ()

@property LCCUser *user;
@property CommListMode mode;
@property NSArray *posts;

@end

@implementation CommDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsChangeNotification object:nil];
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
    self.user = user;
    self.mode = mode;
    
    [self updateData];
}

- (void)onFollowsChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeNews)
    {
        [self updateData];
    }
}

- (void)updateData
{
    switch (self.mode)
    {
        case CommListModeNews: {
            self.title = @"News";
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
            [query whereKey:@"user" containedIn:[[CommunityModel sharedInstance] arrayWithFollowedUser]];
            [query includeKey:@"sharedPost"];
            [query includeKey:@"user"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                self.posts = objects;
                [self.tableView reloadData];
            }];
            break;
        }
        case CommListModeProfile: {
            self.title = self.user.username;
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
            [query whereKey:@"user" equalTo:self.user];
            [query includeKey:@"sharedPost"];
            [query includeKey:@"user"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                self.posts = objects;
                [self.tableView reloadData];
            }];
            break;
        }
        case CommListModeFollowers: {
            self.title = [NSString stringWithFormat:@"Followers of %@", self.user.username];
            
            self.posts = nil;
            break;
        }
        case CommListModeFollowing: {
            self.title = [NSString stringWithFormat:@"Following %@", self.user.username];
            
            self.posts = nil;
            break;
        }
        case CommListModeUndefined:
            break;
    }
}

- (IBAction)onActionTapped:(id)sender
{
    if ([self.user isMe])
    {
        // Edit
        //TODO
    }
    else if ([[CommunityModel sharedInstance] followWithUser:self.user])
    {
        [[CommunityModel sharedInstance] unfollowUser:self.user];
    }
    else
    {
        [[CommunityModel sharedInstance] followUser:self.user];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (self.mode == CommListModeProfile)
        {
            return 3;
        }
    }
    else if (section == 1)
    {
        return self.posts.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.rowHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"User";
    }
    else if (section == 1)
    {
        return @"Posts";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
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
    }
    else if (indexPath.section == 1)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProgramCell" forIndexPath:indexPath];
        LCCPost *post = self.posts[indexPath.row];
        cell.textLabel.text = post.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", post.user.username, [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
        
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:post.image.url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            CALayer *layer = cell.imageView.layer;
            layer.masksToBounds = YES;
            layer.cornerRadius = 6;
            [cell layoutSubviews];
        }];

        return cell;
    }
    return nil;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ProgramPost"])
    {
        LCCPost *post = self.posts[indexPath.row];
        CommPostViewController *vc = (CommPostViewController *)segue.destinationViewController;
        [vc setPost:post mode:CommPostModeProgram];
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
    self.profileDetailLabel.text = user.about;
    if ([self.user isMe])
    {
        self.actionButton.hidden = NO;
        [self.actionButton setTitle:@"Edit" forState:UIControlStateNormal];
    }
    else if ([[CommunityModel sharedInstance] canFollowOrUnfollow:user])
    {
        self.actionButton.hidden = NO;
        if ([[CommunityModel sharedInstance] followWithUser:user])
        {
            [self.actionButton setTitle:@"Unfollow" forState:UIControlStateNormal];
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
