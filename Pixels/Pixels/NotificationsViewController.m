//
//  NotificationsViewController.m
//  Pixels
//
//  Created by Timo Kloss on 25/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "NotificationsViewController.h"
#import "CommunityModel.h"
#import "UIViewController+LowResCoder.h"
#import "UIViewController+CommUtils.h"
#import "CommPostViewController.h"
#import "AppStyle.h"

@interface NotificationsViewController ()

@property UIActivityIndicatorView *activityIndicator;
@property NSArray <LCCNotification *> *notifications;
@property NSDate *unreadDate;

@end

@implementation NotificationsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicator.hidesWhenStopped = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    self.navigationItem.rightBarButtonItem = activityItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotificationsChanged:) name:NotificationsUpdateNotification object:nil];
    
    self.notifications = [CommunityModel sharedInstance].notifications;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.unreadDate = ((LCCUser *)[PFUser currentUser]).notificationsOpenedDate;
    [[CommunityModel sharedInstance] onOpenNotifications];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationsUpdateNotification object:nil];
}

- (void)onNotificationsChanged:(NSNotification *)notification
{
    if ([CommunityModel sharedInstance].isUpdatingNotifications)
    {
        [self.activityIndicator startAnimating];
    }
    else
    {
        [self.activityIndicator stopAnimating];
        self.notifications = [CommunityModel sharedInstance].notifications;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.refreshControl endRefreshing];
        
        self.unreadDate = ((LCCUser *)[PFUser currentUser]).notificationsOpenedDate;
        [[CommunityModel sharedInstance] onOpenNotifications];
    }
}

- (IBAction)onRefreshPulled:(id)sender
{
    [[CommunityModel sharedInstance] loadNotifications];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
    
    LCCNotification *notification = self.notifications[indexPath.row];
    
    NSString *text;
    switch (notification.type)
    {
        case LCCNotificationTypeComment:
            text = [NSString stringWithFormat:@"%@ commented on '%@'", notification.sender.username, notification.post.title];
            break;
            
        default:
            text = @"Unknown notification";
            break;
    }
    
    BOOL unread = (notification.createdAt.timeIntervalSinceReferenceDate > self.unreadDate.timeIntervalSinceReferenceDate);
    
    cell.textLabel.text = text;
    cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:notification.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    cell.backgroundColor = unread ? [AppStyle brightTintColor] : [AppStyle brightColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LCCNotification *notification = self.notifications[indexPath.row];
    
    switch (notification.type)
    {
        case LCCNotificationTypeComment: {
            CommPostViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommPostView"];
            [vc setPost:notification.post mode:CommPostModePost];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
            
        default:
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
    }
}

@end
