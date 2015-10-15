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

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagSourceCode,
    CellTagPostAuthor,
    CellTagDelete,
    CellTagComment
};

@interface CommPostViewController ()
@property LCCPost *post;
@property NSMutableArray *comments;
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
    if (![self.post isDataAvailable] || self.post.type == LCCPostTypeProgram)
    {
        UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onActionTapped:)];
        [items addObject:actionItem];
    }
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    [items addObject:activityItem];
    self.navigationItem.rightBarButtonItems = items;

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 62;
    
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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostDeleteNotification object:nil];
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

- (void)updateView
{
    self.title = [self.post.title stringWithMaxWords:4];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:(self.post.type == LCCPostTypeProgram ? @"ProgramTitleCell" : @"StatusTitleCell")];
    self.titleCell.post = self.post;
}

- (void)loadAllForceReload:(BOOL)forceReload
{
    if ([self.post isDataAvailable] && !forceReload)
    {
        [self loadSubDataForceReload:NO];
    }
    else
    {
        [self.activityIndicator increaseActivity];
        if (!forceReload)
        {
            self.title = @"Loading...";
        }
        
        PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
        [query includeKey:@"user"];
        [query includeKey:@"stats"];
        query.cachePolicy = forceReload ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheElseNetwork;
        query.maxCacheAge = MAX_CACHE_AGE;
        
        [query getObjectInBackgroundWithId:self.post.objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            [self.activityIndicator decreaseActivity];
            if (object)
            {
                self.post = (LCCPost *)object;
                [self loadSubDataForceReload:forceReload];
            }
            else if (error)
            {
                self.title = @"Error";
                [self showAlertWithTitle:@"Could not load post." message:error.userInfo[@"error"] block:nil];
            }
            
        }];
    }
}

- (void)loadSubDataForceReload:(BOOL)forceReload
{
    [self updateView];
    [self loadUser];
    [self loadCommentsForceReload:forceReload];
    if (self.post.type == LCCPostTypeProgram)
    {
        [self loadProgram];
    }
    [self loadLike];
}

- (void)loadUser
{
    if (![self.post.user isDataAvailable])
    {
        [self.activityIndicator increaseActivity];
        [self.post.user fetchInBackgroundWithBlock:^(PFObject *object,  NSError *error) {
            
            [self.activityIndicator decreaseActivity];
            if (object)
            {
                [self.tableView reloadData];
            }
            else if (error)
            {
                [self showAlertWithTitle:@"Could not load user." message:error.userInfo[@"error"] block:nil];
            }
            
        }];
    }
}

- (void)loadCommentsForceReload:(BOOL)forceReload
{
    self.comments = [NSMutableArray array];
    
    PFQuery *query = [PFQuery queryWithClassName:[LCCComment parseClassName]];
    [query whereKey:@"post" equalTo:self.post];
    [query includeKey:@"user"];
    [query orderByAscending:@"createdAt"];
    query.cachePolicy = forceReload ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheElseNetwork;
    query.maxCacheAge = MAX_CACHE_AGE;
    
    [self.activityIndicator increaseActivity];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        [self.activityIndicator decreaseActivity];
        if (objects)
        {
            self.comments = [NSMutableArray arrayWithArray:objects];
            if (forceReload)
            {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else
            {
                [self.tableView reloadData];
            }
        }
        else if (error)
        {
            [self showAlertWithTitle:@"Could not load comments." message:error.userInfo[@"error"] block:nil];
        }
        [self.refreshControl endRefreshing];
        
    }];
}

- (void)loadProgram
{
    if (self.post.programFile)
    {
        // New format: Load program from file
        
        if ([self.post.programFile isDataAvailable])
        {
            self.titleCell.getProgramButton.enabled = YES;
        }
        else
        {
            [self.activityIndicator increaseActivity];
            [self.post.programFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                
                [self.activityIndicator decreaseActivity];
                if (data)
                {
                    self.titleCell.getProgramButton.enabled = YES;
                }
                else if (error)
                {
                    [self showAlertWithTitle:@"Could not load source code." message:error.userInfo[@"error"] block:nil];
                }
                
            }];
        }
    }
    else
    {
        // Old format: Load program from database object
        
        if ([self.post.program isDataAvailable])
        {
            self.titleCell.getProgramButton.enabled = YES;
        }
        else
        {
            [self.activityIndicator increaseActivity];
            [self.post.program fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                
                [self.activityIndicator decreaseActivity];
                if (object)
                {
                    self.titleCell.getProgramButton.enabled = YES;
                }
                else if (error)
                {
                    [self showAlertWithTitle:@"Could not load source code." message:error.userInfo[@"error"] block:nil];
                }
                
            }];
        }
    }
}

- (void)loadLike
{
    if (![PFUser currentUser])
    {
        // "like" tap will ask for log-in.
        self.titleCell.likeButton.enabled = YES;
    }
    else if (![self.post.user isMe])
    {
        PFQuery *query = [PFQuery queryWithClassName:[LCCCount parseClassName]];
        [query whereKey:@"post" equalTo:self.post];
        [query whereKey:@"type" equalTo:@(LCCCountTypeLike)];
        [query whereKey:@"user" equalTo:[PFUser currentUser]];
        
        [self.activityIndicator increaseActivity];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError *PF_NULLABLE_S error) {
            
            if (error)
            {
                NSLog(@"Error: %@", error.description);
            }
            else if (number > 0)
            {
                [self.titleCell likeIt];
            }
            else
            {
                self.titleCell.likeButton.enabled = YES;
            }
            [self.activityIndicator decreaseActivity];
            
        }];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (IBAction)onLikeTapped:(id)sender
{
    if (![PFUser currentUser])
    {
        CommLogInViewController *vc = [CommLogInViewController create];
        [self presentInNavigationViewController:vc];
    }
    else
    {
        [[CommunityModel sharedInstance] countPost:self.post type:LCCCountTypeLike];
        self.titleCell.likeCount++;
        [self.titleCell likeIt];
        
        NSDictionary *dimensions = @{@"category": [self.post categoryString],
                                     @"app": ([AppController sharedController].isFullVersion) ? @"full version" : @"free"};
        [PFAnalytics trackEvent:@"like" dimensions:dimensions];
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
    LCCPost *post = [LCCPost object];
    post.user = (LCCUser *)[PFUser currentUser];
    post.type = LCCPostTypeShare;
    post.category = self.post.category;
    post.image = self.post.image;
    post.title = self.post.title;
    post.detail = self.post.detail;
    post.stats = self.post.stats;
    post.sharedPost = self.post;
    
    [self.activityIndicator increaseActivity];
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        [self.activityIndicator decreaseActivity];
        if (succeeded)
        {
            [[CommunityModel sharedInstance] onPostedWithDate:post.createdAt];
            [self showAlertWithTitle:@"Shared successfully." message:nil block:nil];
            
            [PFQuery clearAllCachedResults];
        }
        else if (error)
        {
            [self showAlertWithTitle:@"Could not share post." message:error.userInfo[@"error"] block:nil];
        }
        
    }];
}

- (IBAction)onSendCommentTapped:(id)sender
{
    NSString *commentText = self.writeCommentCell.textView.text;
    commentText = [commentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (commentText.length > 0)
    {
        [self.view endEditing:YES];
        
        LCCComment *comment = [LCCComment object];
        comment.user = (LCCUser *)[PFUser currentUser];
        comment.post = self.post;
        comment.text = commentText;
        
        UIButton *button = (UIButton *)sender;
        
        [self.activityIndicator increaseActivity];
        button.enabled = NO;
        
        [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            [self.activityIndicator decreaseActivity];
            
            if (succeeded)
            {
                [self.writeCommentCell reset];

                [self.comments addObject:comment];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.comments.count - 1 inSection:1];
                
                if (self.comments.count == 1)
                {
                    // first comment (need to refresh headers)
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
                }
                else
                {
                    // later comment
                    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                }
                
                NSDictionary *dimensions = @{@"category": [self.post categoryString],
                                             @"user": [PFUser currentUser] ? @"registered" : @"guest",
                                             @"app": ([AppController sharedController].isFullVersion) ? @"full version" : @"free"};
                [PFAnalytics trackEvent:@"comment" dimensions:dimensions];
                
                [[AppController sharedController] registerForNotifications];
                
                [PFQuery clearAllCachedResults];
            }
            else if (error)
            {
                [self showAlertWithTitle:@"Could not send comment." message:error.userInfo[@"error"] block:nil];
            }

            button.enabled = YES;
            
        }];
    }
}

- (void)deletePost
{
    [self.activityIndicator increaseActivity];
    self.view.userInteractionEnabled = NO;
    
    [self.post deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        [self.activityIndicator decreaseActivity];
        self.view.userInteractionEnabled = YES;
        if (succeeded)
        {
            [PFQuery clearAllCachedResults];
            [[NSNotificationCenter defaultCenter] postNotificationName:PostDeleteNotification object:self userInfo:@{@"postId": self.post.objectId}];
        }
        else if (error)
        {
            [self showAlertWithTitle:@"Could not delete post." message:error.userInfo[@"error"] block:nil];
        }
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return ([self.post isDataAvailable] ? 3 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
    {
        NSInteger num = (self.post.type == LCCPostTypeProgram ? 3 : 2);
        if ([self.post.user isMe])
        {
            num++; // "delete" cell
        }
        return num;
    }
    else if (section == 1)
    {
        return self.comments.count;
    }
    else if (section == 2)
    {
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return (self.post.type == LCCPostTypeProgram ? [self.post categoryString] : @"Status Update");
    }
    else if (section == 1)
    {
        return (self.comments.count > 0) ? @"Comments" : @"No Comments Yet";
    }
    else if (section == 2)
    {
        NSString *name = ([PFUser currentUser] ? [PFUser currentUser].username : @"Guest");
        return [NSString stringWithFormat:@"Write a Comment (as %@)", name];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            return self.titleCell;
        }
        else if (indexPath.row == 1)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"By %@", [self.post.user isDataAvailable] ? self.post.user.username : @"..."];
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
    else if (indexPath.section == 1)
    {
        LCCComment *comment = self.comments[indexPath.row];
        CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
        cell.textView.text = comment.text;
        
        NSString *name;
        if (comment.user)
        {
            name = comment.user.username;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.tag = CellTagComment;
        }
        else
        {
            name = @"Guest";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.tag = CellTagNoAction;
        }
        cell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", name, [NSDateFormatter localizedStringFromDate:comment.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
        return cell;
    }
    else if (indexPath.section == 2)
    {
        return self.writeCommentCell;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag)
    {
        case CellTagSourceCode: {
            if ([self.post isDataAvailable] && ([self.post.program isDataAvailable] || [self.post.programFile isDataAvailable]))
            {
                CommSourceCodeViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommSourceCodeView"];
                vc.post = self.post;
                [self.navigationController pushViewController:vc animated:YES];
            }
            else
            {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            break;
        }
        case CellTagPostAuthor: {
            if ([self.post.user isDataAvailable])
            {
                CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
                [vc setUser:self.post.user mode:CommListModeProfile];
                [self.navigationController pushViewController:vc animated:YES];
            }
            else
            {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
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
        case CellTagComment: {
            LCCComment *comment = self.comments[indexPath.row];
            CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
            [vc setUser:comment.user mode:CommListModeProfile];
            [self.navigationController pushViewController:vc animated:YES];
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
    
    if (self.getProgramButton)
    {
        self.getProgramButton.enabled = NO;
    }
    
    self.likeButton.enabled = NO;
    
    LCCUser *currentUser = (LCCUser *)[PFUser currentUser];
    self.shareButton.hidden = ![currentUser isNewsUser];
}

- (void)setPost:(LCCPost *)post
{
    if (post != _post)
    {
        _post = post;
        if (post.image)
        {
            [self.programImage sd_setImageWithURL:[NSURL URLWithString:post.image.url]];
        }
        self.titleTextView.text = post.title;
        self.detailTextView.text = [post.detail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.dateLabel.text = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
        
        self.shareButton.enabled = ![post.user isMe];
        
        if (post.stats.isDataAvailable)
        {
            self.likeCount = post.stats.numLikes;
            self.downloadCount = post.stats.numDownloads;
        }
        else
        {
            self.likeCount = 0;
            self.downloadCount = 0;
        }
    }
}

- (void)setLikeCount:(NSInteger)likeCount
{
    _likeCount = likeCount;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)likeCount];
}

- (void)setDownloadCount:(NSInteger)downloadCount
{
    _downloadCount = downloadCount;
    if (self.downloadCountLabel)
    {
        self.downloadCountLabel.text = [NSString stringWithFormat:@"%ld", (long)downloadCount];
    }
}

- (void)likeIt
{
    [self.likeButton setTitle:@"You like this" forState:UIControlStateNormal];
    self.likeButton.enabled = NO;
}

@end

@implementation CommentCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
}

@end

@implementation WriteCommentCell

- (void)reset
{
    self.textView.text = @"";
}

@end
