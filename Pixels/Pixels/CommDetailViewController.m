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

@interface CommDetailViewController ()

@property LCCUser *user;
@property CommListMode mode;
@property NSArray *posts;

@end

@implementation CommDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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

- (void)updateData
{
    switch (self.mode)
    {
        case CommListModeNews: {
            self.title = @"News";
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.posts.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ProgramCell" forIndexPath:indexPath];
        LCCPost *post = self.posts[indexPath.row];
        cell.textLabel.text = post.title;
        cell.detailTextLabel.text = post.detail;
        
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:post.image.url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            CALayer *layer = cell.imageView.layer;
            layer.masksToBounds = YES;
            layer.cornerRadius = 6;
            [cell layoutSubviews];
        }];
    }
    
    return cell;
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
