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
    CellTagDelete
};

typedef NS_ENUM(NSInteger, Section) {
    SectionTitle,
    SectionComments,
    SectionWriteComment,
    Section_count
};

@interface CommPostViewController ()
@property LCCPost *post;
@property NSMutableArray *comments;
@property CommPostMode mode;
@property ProgramTitleCell *titleCell;
@property WriteCommentCell *writeCommentCell;
@property ExtendedActivityIndicatorView *activityIndicator;
@property BOOL wasDeleted;
@property BOOL isLoadingComments;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCounterChanged:) name:PostCounterChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostCounterChangeNotification object:nil];
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

- (void)onCounterChanged:(NSNotification *)notification
{
    NSString *counterPostId = notification.userInfo[@"postId"];
    if ([counterPostId isEqualToString:self.post.objectId])
    {
        StatsType type = [notification.userInfo[@"type"] integerValue];
        if (self.post.stats)
        {
            self.titleCell.likeCount = self.post.stats.numLikes;
            self.titleCell.downloadCount = self.post.stats.numDownloads;
        }
        if (type == StatsTypeLike)
        {
            [self.titleCell likeIt];
        }
    }
}

- (void)updatePostView
{
    self.title = [self.post.title stringWithMaxWords:4];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:(self.post.type == LCCPostTypeProgram ? @"ProgramTitleCell" : @"StatusTitleCell")];
    self.titleCell.post = self.post;
}

- (void)loadAllForceReload:(BOOL)forceReload
{
    if ([self.post isDataAvailable])
    {
        if (!forceReload)
        {
            [self updatePostView];
        }
        [self loadUser];
        [self loadStatsForceReload:forceReload];
        [self loadSubDataForceReload:forceReload];
    }
    else
    {
        [self.activityIndicator increaseActivity];
        
        self.title = @"Loading...";

        PFQuery *query = [PFQuery queryWithClassName:[LCCPost parseClassName]];
        [query includeKey:@"user"];
        [query includeKey:@"stats"];
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
        query.maxCacheAge = MAX_CACHE_AGE;
        
        [query getObjectInBackgroundWithId:self.post.objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            [self.activityIndicator decreaseActivity];
            if (object)
            {
                self.post = (LCCPost *)object;
                [self updatePostView];
                [self loadSubDataForceReload:NO];
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
    [self loadLike];
    [self loadCommentsForceReload:forceReload];
    if (self.post.type == LCCPostTypeProgram)
    {
        [self loadProgram];
    }
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
    self.isLoadingComments = YES;
    
    PFQuery *query = [PFQuery queryWithClassName:[LCCComment parseClassName]];
    [query whereKey:@"post" equalTo:self.post];
    [query includeKey:@"user"];
    [query orderByAscending:@"createdAt"];
    query.cachePolicy = forceReload ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheElseNetwork;
    query.maxCacheAge = MAX_CACHE_AGE;
    
    NSArray *oldComments = self.comments.copy;
    
    [self.activityIndicator increaseActivity];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        [self.activityIndicator decreaseActivity];
        self.isLoadingComments = NO;
        if (objects)
        {
            self.comments = [NSMutableArray arrayWithArray:objects];
        }
        else if (error)
        {
            self.comments = [NSMutableArray array];
            [self showAlertWithTitle:@"Could not load comments." message:error.userInfo[@"error"] block:nil];
        }
        
        if (forceReload)
        {
            [self.tableView reloadDataAnimatedWithOldArray:oldComments newArray:self.comments inSection:SectionComments offset:0];
        }
        else
        {
            [self.tableView reloadData];
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

- (void)loadStatsForceReload:(BOOL)forceReload
{
    if (self.post.stats && (!self.post.stats.isDataAvailable || forceReload))
    {
        [self.activityIndicator increaseActivity];
        [self.post.stats fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            [self.activityIndicator decreaseActivity];
            if (object)
            {
                self.titleCell.likeCount = self.post.stats.numLikes;
                self.titleCell.downloadCount = self.post.stats.numDownloads;
            }
            else if (error)
            {
                [self showAlertWithTitle:@"Could not load statistics." message:error.userInfo[@"error"] block:nil];
            }
            
        }];
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
    else if (![self.post.user isMe])
    {
        [[CommunityModel sharedInstance] countPost:self.post type:StatsTypeLike];
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
            [PFQuery clearAllCachedResults];
            
            [self showAlertWithTitle:@"Shared successfully." message:nil block:nil];
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
        
        [self.activityIndicator increaseActivity];
        
        UIButton *button = (UIButton *)sender;
        button.enabled = NO;
        
        // Comment
        LCCComment *comment = [LCCComment object];
        comment.user = (LCCUser *)[PFUser currentUser];
        comment.post = self.post;
        comment.text = commentText;
        
        // Stats
        if (!self.post.stats)
        {
            self.post.stats = [LCCPostStats object];
        }
        [self.post.stats incrementKey:@"numComments"];
        
        // UI Notification
        [[NSNotificationCenter defaultCenter] postNotificationName:PostCounterChangeNotification object:self userInfo:@{@"postId":self.post.objectId, @"type":@(StatsTypeComment)}];
        
        // Save to server
        [PFObject saveAllInBackground:@[comment, self.post.stats] block:^(BOOL succeeded, NSError * _Nullable error) {
            
            [self.activityIndicator decreaseActivity];
            
            if (succeeded)
            {
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
                
                [[CommunityModel sharedInstance] trackEvent:@"comment" forPost:self.post];
                
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
    return ([self.post isDataAvailable] ? Section_count : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == SectionTitle)
    {
        NSInteger num = (self.post.type == LCCPostTypeProgram ? 3 : 2);
        if ([self.post.user isMe])
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
        return (self.isLoadingComments) ? @"Loading Comments..." : (self.comments.count > 0) ? @"Comments" : @"No Comments Yet";
    }
    else if (section == SectionWriteComment)
    {
        NSString *name = ([PFUser currentUser] ? [PFUser currentUser].username : @"Guest");
        return [NSString stringWithFormat:@"Write a Comment (as %@)", name];
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
    else if (indexPath.section == SectionComments)
    {
        CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.comment = self.comments[indexPath.row];
        return cell;
    }
    else if (indexPath.section == SectionWriteComment)
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
                [self showUser:self.post.user];
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


@interface CommentCell()
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@end

@implementation CommentCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.tag = CellTagNoAction;
}

- (void)setComment:(LCCComment *)comment
{
    _comment = comment;
    if (comment.user)
    {
        [self.nameButton setTitle:comment.user.username forState:UIControlStateNormal];
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
    [self.delegate showUser:self.comment.user];
}

@end

@implementation WriteCommentCell

- (void)reset
{
    self.textView.text = @"";
}

@end
