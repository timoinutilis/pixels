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

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagPost,
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
            
            NSArray *followedUsers = [[CommunityModel sharedInstance] arrayWithFollowedUser];
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
                        self.posts = objects;
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
            self.title = nil;
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.user.username style:UIBarButtonItemStylePlain target:nil action:nil];
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
            [query whereKey:@"user" equalTo:self.user];
            [query includeKey:@"sharedPost"];
            [query includeKey:@"user"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (objects)
                {
                    self.posts = objects;
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
        else if (self.mode == CommListModeNews)
        {
            return 1;
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
        return (self.mode == CommListModeNews) ? @"Info" : @"User";
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
        else if (self.mode == CommListModeNews)
        {
            CommInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommInfoCell" forIndexPath:indexPath];
            cell.infoTextLabel.text = @"Here you see the posts of all the users you follow.";
            return cell;
        }
    }
    else if (indexPath.section == 1)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProgramCell" forIndexPath:indexPath];
        LCCPost *post = self.posts[indexPath.row];
        cell.textLabel.text = post.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", post.user.username, [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
        cell.tag = CellTagPost;
        
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
            [vc setPost:post mode:CommPostModeProgram];
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


@implementation CommInfoCell
@end
