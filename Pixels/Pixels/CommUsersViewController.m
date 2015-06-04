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

@interface CommUsersViewController ()

@property LCCUser *user;
@property CommUsersMode mode;
@property NSMutableArray *users;

@end

@implementation CommUsersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)setUser:(LCCUser *)user mode:(CommUsersMode)mode
{
    self.user = user;
    self.mode = mode;
    
    [self updateData];
}

- (void)updateData
{
    switch (self.mode)
    {
        case CommUsersModeFollowers: {
            self.title = @"Followers";
            
            PFQuery *query = [PFQuery queryWithClassName:[LCCFollow parseClassName]];
            [query whereKey:@"followsUser" equalTo:self.user];
            [query includeKey:@"user"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                self.users = [NSMutableArray arrayWithCapacity:objects.count];
                for (LCCFollow *follow in objects)
                {
                    [self.users addObject:follow.user];
                }
                [self.tableView reloadData];
                
            }];
            break;
        }
        case CommUsersModeFollowing: {
            self.title = @"Following";

            PFQuery *query = [PFQuery queryWithClassName:[LCCFollow parseClassName]];
            [query whereKey:@"user" equalTo:self.user];
            [query includeKey:@"followsUser"];
            [query orderByDescending:@"createdAt"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                self.users = [NSMutableArray arrayWithCapacity:objects.count];
                for (LCCFollow *follow in objects)
                {
                    [self.users addObject:follow.followsUser];
                }
                [self.tableView reloadData];
                
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