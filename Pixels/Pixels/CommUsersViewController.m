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
#import "UITableView+Parse.h"

@interface CommUsersViewController ()

@property LCCUser *user;
@property CommUsersMode mode;
@property NSMutableArray *users;
@property ExtendedActivityIndicatorView *activityIndicator;

@end

@implementation CommUsersViewController

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

}

- (void)setUser:(LCCUser *)user mode:(CommUsersMode)mode
{
    self.user = user;
    self.mode = mode;
    
    [self updateDataForceReload:NO];
    
    self.title = (self.mode == CommUsersModeFollowers) ? @"Followers" : @"Following";
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
    NSString *route;
    if (self.mode == CommUsersModeFollowers)
    {
        route = [NSString stringWithFormat:@"/users/%@/followers", self.user.objectId];
    }
    else
    {
        route = [NSString stringWithFormat:@"/users/%@/following", self.user.objectId];
    }
    
    [self.activityIndicator increaseActivity];
    
    [[CommunityModel sharedInstance].sessionManager GET:route parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

        [self.activityIndicator decreaseActivity];
        NSArray *oldUsers = self.users.copy;
        self.users = [LCCUser objectsFromArray:responseObject[@"users"]].mutableCopy;
        if (forceReload)
        {
            [self.tableView reloadDataAnimatedWithOldArray:oldUsers newArray:self.users inSection:0 offset:0];
        }
        else
        {
            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        [self.activityIndicator decreaseActivity];
        [self.refreshControl endRefreshing];
        [self showAlertWithTitle:@"Could not load users" message:error.presentableError.localizedDescription block:nil];

    }];
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
