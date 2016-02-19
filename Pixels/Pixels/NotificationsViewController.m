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
#import "CommDetailViewController.h"
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
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 63;
    
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
    NotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
    
    LCCNotification *notification = self.notifications[indexPath.row];
    cell.notification = notification;
    cell.isUnread = (notification.createdAt.timeIntervalSinceReferenceDate > self.unreadDate.timeIntervalSinceReferenceDate);
    
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
            
        case LCCNotificationTypeLike:
        case LCCNotificationTypeShare:
        case LCCNotificationTypeFollow: {
            CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
            [vc setUser:notification.sender mode:CommListModeProfile];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        
        default:
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
    }
}

@end


@interface NotificationCell()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@end

@implementation NotificationCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
}

- (void)setNotification:(LCCNotification *)notification
{
    _notification = notification;
    
    NSString *text;
    NSString *name = (notification.sender != nil) ? notification.sender.username : @"A guest";
    switch (notification.type)
    {
        case LCCNotificationTypeComment:
            text = [NSString stringWithFormat:@"%@ commented on '%@'", name, notification.post.title];
            break;
            
        case LCCNotificationTypeLike:
            text = [NSString stringWithFormat:@"%@ likes '%@'", name, notification.post.title];
            break;
            
        case LCCNotificationTypeShare:
            text = [NSString stringWithFormat:@"%@ shared '%@'", name, notification.post.title];
            break;
            
        case LCCNotificationTypeFollow:
            text = [NSString stringWithFormat:@"%@ follows you", name];
            break;
            
        default:
            text = @"Unknown notification";
            break;
    }
    
    self.textView.text = text;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.dateLabel.text = [NSDateFormatter localizedStringFromDate:notification.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
}

- (void)setIsUnread:(BOOL)isUnread
{
    _isUnread = isUnread;
    if (isUnread)
    {
        self.backgroundColor = [AppStyle brightTintColor];
        self.textView.backgroundColor = [AppStyle brightTintColor];
    }
    else
    {
        self.backgroundColor = [AppStyle brightColor];
        self.textView.backgroundColor = [AppStyle brightColor];
    }
}

@end
