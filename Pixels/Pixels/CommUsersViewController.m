//
//  CommUsersViewController.m
//  Pixels
//
//  Created by Timo Kloss on 25/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommUsersViewController.h"
#import "CommunityModel.h"
#import "CommDetailViewController.h"
#import "ExtendedActivityIndicatorView.h"
#import "UIViewController+LowResCoder.h"
#import "UIViewController+CommUtils.h"

@interface CommUsersViewController ()

@property LCCUser *user;
@property CommUsersMode mode;
@property NSMutableArray *users;
@property ExtendedActivityIndicatorView *activityIndicator;

@end

@implementation CommUsersViewController

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

}

- (void)setUser:(LCCUser *)user mode:(CommUsersMode)mode
{
    self.user = user;
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

- (void)updateDataForceReload:(BOOL)forceReload
{
    switch (self.mode)
    {
        case CommUsersModeFollowers: {
            self.title = @"Followers";
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCFollow parseClassName]];
            [query whereKey:@"followsUser" equalTo:self.user];
            [query includeKey:@"user"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = forceReload ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheElseNetwork;
            query.maxCacheAge = MAX_CACHE_AGE;
            
            BOOL wasCached = query.hasCachedResult && !forceReload;
            
            [self.activityIndicator increaseActivity];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                [self.activityIndicator decreaseActivity];
                if (objects)
                {
                    self.users = [NSMutableArray arrayWithCapacity:objects.count];
                    for (LCCFollow *follow in objects)
                    {
                        [self.users addObject:follow.user];
                    }
                    if (wasCached)
                    {
                        [self.tableView reloadData];
                    }
                    else
                    {
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }
                else if (error)
                {
                    [self showAlertWithTitle:@"Could not load users" message:error.userInfo[@"error"] block:nil];
                }
                [self.refreshControl endRefreshing];
                
            }];
            break;
        }
        case CommUsersModeFollowing: {
            self.title = @"Following";

            PFQuery *query = [PFQuery queryWithClassName:[LCCFollow parseClassName]];
            [query whereKey:@"user" equalTo:self.user];
            [query includeKey:@"followsUser"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = forceReload ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheElseNetwork;
            query.maxCacheAge = MAX_CACHE_AGE;
            
            BOOL wasCached = query.hasCachedResult && !forceReload;
            
            [self.activityIndicator increaseActivity];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                [self.activityIndicator decreaseActivity];
                if (objects)
                {
                    self.users = [NSMutableArray arrayWithCapacity:objects.count];
                    for (LCCFollow *follow in objects)
                    {
                        [self.users addObject:follow.followsUser];
                    }
                    if (wasCached)
                    {
                        [self.tableView reloadData];
                    }
                    else
                    {
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }
                else if (error)
                {
                    [self showAlertWithTitle:@"Could not load users" message:error.userInfo[@"error"] block:nil];
                }
                [self.refreshControl endRefreshing];
                
            }];
            break;
        }
        case CommUsersModeUndefined:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LCCUser *user = self.users[indexPath.row];
    
    CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
    [vc setUser:user mode:CommListModeProfile];
    [self.navigationController pushViewController:vc animated:YES];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    LCCUser *user = self.users[indexPath.row];
    cell.textLabel.text = user.username;
    
    return cell;
}

@end
