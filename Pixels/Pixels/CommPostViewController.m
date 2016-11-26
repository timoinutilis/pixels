//
//  CommPostViewController.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommPostViewController.h"
#import "CommunityModel.h"
#import "UIImageView+WebCache.h"
#import "CommSourceCodeViewController.h"
#import "CommDetailViewController.h"
#import "CommLogInViewController.h"
#import "UIViewController+CommUtils.h"
#import "UIViewController+LowResCoder.h"
#import "ExtendedActivityIndicatorView.h"
#import "NSString+Utils.h"
#import "AppController.h"
#import "UITableView+Parse.h"

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagSourceCode,
    CellTagPostAuthor,
    CellTagDelete,
    CellTagLogin
};

typedef NS_ENUM(NSInteger, Section) {
    SectionTitle,
    SectionComments,
    SectionWriteComment,
    Section_count
};

@interface CommPostViewController ()

@property LCCPost *post;
@property LCCUser *user;
@property LCCPostStats *stats;
@property NSMutableArray *comments;
@property NSMutableDictionary *commentUsersById;

@property CommPostMode mode;
@property ProgramTitleCell *titleCell;
@property WriteCommentCell *writeCommentCell;
@property ExtendedActivityIndicatorView *activityIndicator;
@property BOOL wasDeleted;

@end

@implementation CommPostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.activityIndicator = [[ExtendedActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    NSMutableArray *items = [NSMutableArray array];
    if ([self isModal])
    {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneTapped:)];
        [items addObject:doneItem];
    }
    if (   self.post.title == nil // opened from editor, so it's a program
        || self.post.type == LCCPostTypeProgram)
    {
        UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onActionTapped:)];
        [items addObject:actionItem];
    }
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    [items addObject:activityItem];
    self.navigationItem.rightBarButtonItems = items;

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0"))
    {
        // simple workaround for Split View bug, Table View doesn't adjust for Keyboard on iPhone
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && self.splitViewController)
        {
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 252, 0);
        }
    }
    
    self.writeCommentCell = [self.tableView dequeueReusableCellWithIdentifier:@"WriteCommentCell"];
    
    [self loadAllForceReload:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPostDeleted:) name:PostDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatsChanged:) name:PostStatsChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostStatsChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.wasDeleted)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)setPost:(LCCPost *)post mode:(CommPostMode)mode
{
    self.post = post;
    self.mode = mode;
}

- (IBAction)onRefreshPulled:(id)sender
{
    [self loadAllForceReload:YES];
}

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onActionTapped:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://lowres.inutilis.com/programs/?lccpost=%@", self.post.objectId]];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    
    activityVC.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)onPostDeleted:(NSNotification *)notification
{
    NSString *deletedPostId = notification.userInfo[@"postId"];
    if ([deletedPostId isEqualToString:self.post.objectId])
    {
        if (self.navigationController.topViewController == self)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            self.wasDeleted = YES;
        }
    }
}

- (void)onStatsChanged:(NSNotification *)notification
{
    LCCPostStats *stats = notification.userInfo[@"stats"];
    if ([stats.post isEqualToString:self.post.objectId])
    {
        int oldLikes = self.stats.numLikes;
        self.stats = stats;
        [self.titleCell setStats:stats];

        if (stats.numLikes > oldLikes)
        {
            [self.titleCell likeIt];
        }
    }
}

- (void)loadAllForceReload:(BOOL)forceReload
{
    [self.activityIndicator increaseActivity];
    self.title = self.post.title ? [self.post.title stringWithMaxWords:4] : @"Loading...";
    
    LCCUser *currentUser = [CommunityModel sharedInstance].currentUser;
    
    NSString *route = [NSString stringWithFormat:@"posts/%@", self.post.objectId];
    NSDictionary *params = currentUser ? @{@"likedUserId": currentUser.objectId} : nil;
    [[CommunityModel sharedInstance].sessionManager GET:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [self.activityIndicator decreaseActivity];
        
        NSArray *oldComments = self.comments.copy;
        
        [self.post updateWithDictionary:responseObject[@"post"]];
        self.user = [[LCCUser alloc] initWithDictionary:responseObject[@"user"]];
        self.stats = [[LCCPostStats alloc] initWithDictionary:responseObject[@"stats"]];
        self.comments = [LCCComment objectsFromArray:responseObject[@"comments"]].mutableCopy;
        self.commentUsersById = [LCCUser objectsByIdFromArray:responseObject[@"users"]].mutableCopy;
        BOOL liked = [responseObject[@"liked"] boolValue];
        
        self.title = [self.post.title stringWithMaxWords:4];
        
        self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:(self.post.type == LCCPostTypeProgram ? @"ProgramTitleCell" : @"StatusTitleCell")];
        [self.titleCell setPost:self.post user:self.user];
        [self.titleCell setStats:self.stats];
        
        if (currentUser)
        {
            if (liked)
            {
                [self.titleCell likeIt];
            }
            else
            {
                self.titleCell.likeButton.enabled = ![self.user isMe];
            }
        }
        else
        {
            // "like" tap will ask for log-in.
            self.titleCell.likeButton.enabled = YES;
        }
        
        if (forceReload)
        {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SectionTitle]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadDataAnimatedWithOldArray:oldComments newArray:self.comments inSection:SectionComments offset:0];
        }
        else
        {
            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        self.title = @"Error";
        [self showAlertWithTitle:@"Could not load post." message:error.presentableError.localizedDescription block:nil];

    }];
}

- (void)onUserChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (IBAction)onLikeTapped:(id)sender
{
    if (![CommunityModel sharedInstance].currentUser)
    {
        CommLogInViewController *vc = [CommLogInViewController create];
        [self presentInNavigationViewController:vc];
    }
    else if (![self.user isMe])
    {
        [[CommunityModel sharedInstance] likePost:self.post];
    }
}

- (IBAction)onGetProgramTapped:(id)sender
{
    [self onGetProgramTappedWithPost:self.post];
}

- (IBAction)onShareTapped:(id)sender
{
    CommPostViewController __weak *weakSelf = self;
    [self showConfirmAlertWithTitle:@"Do you really want to share this?" message:nil block:^{
        [weakSelf share];
    }];
}

- (void)share
{
    LCCPost *post = [[LCCPost alloc] init];
    post.type = LCCPostTypeShare;
    post.category = self.post.category;
    post.image = self.post.image;
    post.title = self.post.title;
    post.stats = self.post.stats;
    post.sharedPost = self.post.objectId;
    
    [self.activityIndicator increaseActivity];
    
    NSString *route = [NSString stringWithFormat:@"/users/%@/posts", [CommunityModel sharedInstance].currentUser.objectId];
    NSDictionary *params = [post dirtyDictionary];
    [[CommunityModel sharedInstance].sessionManager POST:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [self.activityIndicator decreaseActivity];
//        [PFQuery clearAllCachedResults];
        [self showAlertWithTitle:@"Shared successfully." message:nil block:nil];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        [self.activityIndicator decreaseActivity];
        [self showAlertWithTitle:@"Could not share post." message:error.presentableError.localizedDescription block:nil];
        
    }];
}

- (IBAction)onSendCommentTapped:(id)sender
{
    NSString *commentText = self.writeCommentCell.textView.text;
    commentText = [commentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (commentText.length > 0)
    {
        [self.view endEditing:YES];
        
        [self.activityIndicator increaseActivity];
        
        UIButton *button = (UIButton *)sender;
        button.enabled = NO;

        LCCUser *currentUser = [CommunityModel sharedInstance].currentUser;
        self.commentUsersById[currentUser.objectId] = currentUser;
        
        // Comment
        LCCComment *comment = [[LCCComment alloc] init];
        comment.user = currentUser.objectId;
        comment.text = commentText;
        
        
        NSString *route = [NSString stringWithFormat:@"/posts/%@/comments", self.post.objectId];
        NSDictionary *params = [comment dirtyDictionary];
        
        [[CommunityModel sharedInstance].sessionManager POST:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

            [self.activityIndicator decreaseActivity];
            [comment updateWithDictionary:responseObject[@"comment"]];
            [comment resetDirty];
            
            LCCPostStats *stats = [[LCCPostStats alloc] initWithDictionary:responseObject[@"postStats"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:PostStatsChangeNotification object:self userInfo:@{@"stats":stats}];
            
            [self.writeCommentCell reset];
            
            [self.comments addObject:comment];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.comments.count - 1 inSection:1];
            
            if (self.comments.count == 1)
            {
                // first comment (need to refresh headers)
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else
            {
                // later comment
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            [[AppController sharedController] registerForNotifications];
            
//            [PFQuery clearAllCachedResults];
            
            button.enabled = YES;

        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

            [self.activityIndicator decreaseActivity];
            [self showAlertWithTitle:@"Could not send comment." message:error.presentableError.localizedDescription block:nil];
            button.enabled = YES;
            
        }];
    }
}

- (void)deletePost
{
    [self.activityIndicator increaseActivity];
    self.view.userInteractionEnabled = NO;
    
    NSString *route = [NSString stringWithFormat:@"/posts/%@", self.post.objectId];
    [[CommunityModel sharedInstance].sessionManager DELETE:route parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

        [self.activityIndicator decreaseActivity];
        self.view.userInteractionEnabled = YES;
//        [PFQuery clearAllCachedResults];
        [[NSNotificationCenter defaultCenter] postNotificationName:PostDeleteNotification object:self userInfo:@{@"postId": self.post.objectId}];

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        [self.activityIndicator decreaseActivity];
        self.view.userInteractionEnabled = YES;
        [self showAlertWithTitle:@"Could not delete post." message:error.presentableError.localizedDescription block:nil];

    }];
}

- (void)showUser:(LCCUser *)user
{
    CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
    [vc setUser:user mode:CommListModeProfile];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Table view

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionTitle && indexPath.row == 0)
    {
        return 259;
    }
    else if (indexPath.section == SectionComments)
    {
        return 66;
    }
    else if (indexPath.section == SectionWriteComment)
    {
        return 126;
    }
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return (self.comments != nil ? Section_count : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == SectionTitle)
    {
        NSInteger num = (self.post.type == LCCPostTypeProgram ? 3 : 2);
        if ([self.user isMe])
        {
            num++; // "delete" cell
        }
        return num;
    }
    else if (section == SectionComments)
    {
        return self.comments.count;
    }
    else if (section == SectionWriteComment)
    {
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SectionTitle)
    {
        return (self.post.type == LCCPostTypeProgram ? [self.post categoryString] : @"Status Update");
    }
    else if (section == SectionComments)
    {
        return (self.comments.count > 0) ? @"Comments" : @"No Comments Yet";
    }
    else if (section == SectionWriteComment)
    {
        LCCUser *currentUser = [CommunityModel sharedInstance].currentUser;
        if (currentUser)
        {
            return [NSString stringWithFormat:@"Write a Comment (as %@)", currentUser.username];
        }
        return @"Write a Comment (Not Logged In)";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionTitle)
    {
        if (indexPath.row == 0)
        {
            return self.titleCell;
        }
        else if (indexPath.row == 1)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"By %@", self.user.username];
            cell.tag = CellTagPostAuthor;
            return cell;
        }
        else if (indexPath.row == 2 && self.post.type == LCCPostTypeProgram)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Source Code";
            cell.tag = CellTagSourceCode;
            return cell;
        }
        else // row 2 for status or 3 for program
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeleteCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Delete";
            cell.textLabel.textColor = [UIColor redColor];
            cell.tag = CellTagDelete;
            return cell;
        }
    }
    else if (indexPath.section == SectionComments)
    {
        CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
        cell.delegate = self;
        LCCComment *comment = self.comments[indexPath.row];
        [cell setComment:comment user:self.commentUsersById[comment.user]];
        return cell;
    }
    else if (indexPath.section == SectionWriteComment)
    {
        if ([CommunityModel sharedInstance].currentUser)
        {
            return self.writeCommentCell;
        }
        else
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoginCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Log In / Register";
            cell.tag = CellTagLogin;
            return cell;

        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag)
    {
        case CellTagSourceCode: {
            CommSourceCodeViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommSourceCodeView"];
            vc.post = self.post;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case CellTagPostAuthor: {
            [self showUser:self.user];
            break;
        }
        case CellTagDelete: {
            CommPostViewController __weak *weakSelf = self;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do you really want to delete this post?" message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [weakSelf deletePost];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case CellTagLogin: {
            CommLogInViewController *vc = [CommLogInViewController create];
            [self presentInNavigationViewController:vc];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        default:
            break;
    }
}

@end

@interface ProgramTitleCell()
@property (weak, nonatomic) IBOutlet UIImageView *programImage;
@property (weak, nonatomic) IBOutlet UITextView *titleTextView;
@property (weak, nonatomic) IBOutlet UITextView *detailTextView;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *downloadCountLabel;
@end

@implementation ProgramTitleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (self.programImage)
    {
        CALayer *layer = self.programImage.layer;
        layer.masksToBounds = YES;
        layer.cornerRadius = 6;
        layer.borderWidth = 0.5;
        layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
    }
    
    self.titleTextView.textContainer.lineFragmentPadding = 0;
    self.titleTextView.textContainerInset = UIEdgeInsetsZero;
    self.detailTextView.textContainer.lineFragmentPadding = 0;
    self.detailTextView.textContainerInset = UIEdgeInsetsZero;
    
    self.likeButton.enabled = NO;
    
    LCCUser *currentUser = [CommunityModel sharedInstance].currentUser;
    self.shareButton.hidden = ![currentUser isNewsUser];
}

- (void)setPost:(LCCPost *)post user:(LCCUser *)user
{
    if (post.image)
    {
        [self.programImage sd_setImageWithURL:post.image];
    }
    self.titleTextView.text = post.title;
    self.detailTextView.text = [post.detail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.dateLabel.text = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    
    self.shareButton.enabled = ![user isMe];
}

- (void)setStats:(LCCPostStats *)stats
{
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)stats.numLikes];
    self.downloadCountLabel.text = [NSString stringWithFormat:@"%ld", (long)stats.numDownloads];
}

- (void)likeIt
{
    [self.likeButton setTitle:@"Liked ✓" forState:UIControlStateNormal];
    self.likeButton.enabled = NO;
}

@end


@interface CommentCell()
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic) LCCUser *user;
@end

@implementation CommentCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.tag = CellTagNoAction;
}

- (void)setComment:(LCCComment *)comment user:(LCCUser *)user
{
    _user = user;
    if (user)
    {
        [self.nameButton setTitle:user.username forState:UIControlStateNormal];
        self.nameButton.enabled = YES;
    }
    else
    {
        [self.nameButton setTitle:@"Guest" forState:UIControlStateNormal];
        self.nameButton.enabled = NO;
    }
    self.dateLabel.text = [NSDateFormatter localizedStringFromDate:comment.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    self.textView.text = comment.text;
}

- (IBAction)onNameTapped:(id)sender
{
    [self.delegate showUser:self.user];
}

@end

@implementation WriteCommentCell

- (void)reset
{
    self.textView.text = @"";
}

@end
