//
//  CommunityMasterViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommMasterViewController.h"
#import "CommDetailViewController.h"
#import "CommunityModel.h"
#import "CommLogInViewController.h"
#import "UIViewController+LowResCoder.h"
#import "UIViewController+CommUtils.h"
#import "AppController.h"
#import "ActionTableViewCell.h"

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNews,
    CellTagDiscover,
    CellTagAccount,
    CellTagNotifications,
    CellTagLogIn,
    CellTagLogOut,
    CellTagFollowing
};

@interface CommMasterViewController ()

@property NSIndexPath *newsIndexPath;
@property NSIndexPath *currentSelection;

@end

@implementation CommMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotificationsNumChanged:) name:NotificationsNumChangeNotification object:nil];
    
    self.newsIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    self.currentSelection = self.newsIndexPath;
    
    [[CommunityModel sharedInstance] updateCurrentUser];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationsNumChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.clearsSelectionOnViewWillAppear = self.splitViewController.collapsed;
    [super viewWillAppear:animated];
}

- (void)showCurrentSelection
{
    if (!self.splitViewController.collapsed)
    {
        [self.tableView selectRowAtIndexPath:self.currentSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
    if (![CommunityModel sharedInstance].currentUser && ![self.currentSelection isEqual:self.newsIndexPath])
    {
        // show news
        self.currentSelection = self.newsIndexPath;
        if (!self.splitViewController.collapsed)
        {
            [self.tableView selectRowAtIndexPath:self.currentSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self performSegueWithIdentifier:@"Detail" sender:self];
        }
    }
    else
    {
        [self showCurrentSelection];
    }
}

- (void)onFollowsChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
    [self showCurrentSelection];
}

- (void)onNotificationsNumChanged:(NSNotification *)notification
{
    if ([CommunityModel sharedInstance].currentUser)
    {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([CommunityModel sharedInstance].follows.count > 0 ? 3 : 2);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        return @"Your Account";
    }
    else if (section == 2)
    {
        return @"Following";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [CommunityModel sharedInstance].currentUser ? 3 : 1;
    }
    else if (section == 1)
    {
        return [CommunityModel sharedInstance].currentUser ? 2 : 1;
    }
    else if (section == 2)
    {
        return [CommunityModel sharedInstance].follows.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = @"News";
            cell.tag = CellTagNews;
        }
        else if (indexPath.row == 1)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Discover";
            cell.tag = CellTagDiscover;
        }
        else if (indexPath.row == 2)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationsCell" forIndexPath:indexPath];
            NSInteger num = [CommunityModel sharedInstance].numNewNotifications;
            if (num > 0)
            {
                cell.textLabel.text = [NSString stringWithFormat:@"Notifications (%ld)", (long)num];
            }
            else
            {
                cell.textLabel.text = @"Notifications";
            }
            cell.tag = CellTagNotifications;
        }
    }
    else if (indexPath.section == 1)
    {
        if (indexPath.row == 0)
        {
            LCCUser *user = [CommunityModel sharedInstance].currentUser;
            if (user)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
                cell.textLabel.text = user.username;
                cell.tag = CellTagAccount;
            }
            else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Log In / Register";
                cell.tag = CellTagLogIn;
                [((ActionTableViewCell *)cell) setDisabled:NO wheel:NO];
            }
        }
        else if (indexPath.row == 1)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Log Out";
            cell.tag = CellTagLogOut;
        }
    }
    else if (indexPath.section == 2)
    {
        LCCUser *followUser = [CommunityModel sharedInstance].follows[indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
        cell.textLabel.text = followUser.username;
        cell.tag = CellTagFollowing;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag)
    {
        case CellTagLogIn: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            UIViewController *vc = [CommLogInViewController create];
            [self presentInNavigationViewController:vc];
            break;
        }
        case CellTagLogOut: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [((ActionTableViewCell *)cell) setDisabled:YES wheel:YES];
            [[CommunityModel sharedInstance] logOut];
            break;
        }
        default: {
            self.currentSelection = indexPath;
            break;
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Detail"])
    {
        CommDetailViewController *vc = (CommDetailViewController *)[[segue destinationViewController] topViewController];
        
        switch (cell.tag)
        {
            case CellTagNews: {
                LCCUser *user = [CommunityModel sharedInstance].currentUser;
                [vc setUser:user mode:CommListModeNews];
                break;
            }
            case CellTagDiscover: {
                LCCUser *user = [CommunityModel sharedInstance].currentUser;
                [vc setUser:user mode:CommListModeDiscover];
                break;
            }
            case CellTagAccount: {
                LCCUser *user = [CommunityModel sharedInstance].currentUser;
                [vc setUser:user mode:CommListModeProfile];
                break;
            }
            case CellTagFollowing: {
                LCCUser *followUser = [CommunityModel sharedInstance].follows[indexPath.row];
                [vc setUser:followUser mode:CommListModeProfile];
                break;
            }
        }
    }
}

@end
