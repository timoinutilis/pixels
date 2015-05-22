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

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNews,
    CellTagAccount,
    CellTagLogIn,
    CellTagLogOut,
    CellTagFollowing
};

@interface CommMasterViewController ()

@end

@implementation CommMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.clearsSelectionOnViewWillAppear = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)onUserChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
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
        return 1;
    }
    else if (section == 1)
    {
        return [PFUser currentUser] ? 2 : 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
        cell.textLabel.text = @"News";
        cell.tag = CellTagNews;
    }
    else if (indexPath.section == 1)
    {
        if (indexPath.row == 0)
        {
            LCCUser *user = (LCCUser *)[PFUser currentUser];
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
        cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
        cell.textLabel.text = @"User";
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
            UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommLogInViewNav"];
            [self presentViewController:vc animated:YES completion:nil];
            break;
        }
        case CellTagLogOut: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [PFUser logOutInBackgroundWithBlock:^(NSError *error) {
                [tableView reloadData];
            }];
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
                LCCUser *user = (LCCUser *)[PFUser currentUser];
                [vc setUser:user mode:CommListModeNews];
                break;
            }
            case CellTagAccount: {
                LCCUser *user = (LCCUser *)[PFUser currentUser];
                [vc setUser:user mode:CommListModeProfile];
                break;
            }
            case CellTagFollowing: {
                LCCUser *user = nil; //TODO
                [vc setUser:user mode:CommListModeProfile];
                break;
            }
        }
    }
}


@end
