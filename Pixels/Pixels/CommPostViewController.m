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

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagSourceCode,
    CellTagPostAuthor,
    CellTagDelete
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

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.activityIndicator = [[ExtendedActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;
    
    // simple workaround for Split View bug, Table View doesn't adjust for Keyboard on iPhone
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 252, 0);
    }
    
    if (self.navigationController.viewControllers.firstObject == self)
    {
        // is modal
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(onDoneTapped:)];
    }
    
    self.writeCommentCell = [self.tableView dequeueReusableCellWithIdentifier:@"WriteCommentCell"];
    
    [self loadAll];
    
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

- (void)loadAll
{
    if ([self.post isDataAvailable])
    {
        [self loadSubData];
    }
    else
    {
        [self.activityIndicator increaseActivity];
        self.title = @"Loading...";
        [self.post fetchInBackgroundWithBlock:^(PFObject *object,  NSError *error) {
            
            [self.activityIndicator decreaseActivity];
            if (object)
            {
                [self loadSubData];
            }
            else if (error)
            {
                self.title = @"Error";
                [self showAlertWithTitle:@"Could not load post." message:error.userInfo[@"error"] block:nil];
            }
            
        }];
    }
}

- (void)loadSubData
{
    [self updateView];
    [self loadUser];
    [self loadComments];
    if (self.post.type == LCCPostTypeProgram)
    {
        [self loadProgram];
    }
    [self loadCounters];
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

- (void)loadComments
{
    self.comments = [NSMutableArray array];
    
    PFQuery *query = [PFQuery queryWithClassName:[LCCComment parseClassName]];
    [query whereKey:@"post" equalTo:self.post];
    [query includeKey:@"user"];
    [query orderByAscending:@"createdAt"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [self.activityIndicator increaseActivity];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        [self.activityIndicator decreaseActivity];
        if (objects)
        {
            self.comments = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }
        else if (error)
        {
            [self showAlertWithTitle:@"Could not load comments." message:error.userInfo[@"error"] block:nil];
        }
        
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

- (void)loadCounters
{
    // Likes
    [self.activityIndicator increaseActivity];
    [[CommunityModel sharedInstance] fetchCountForPost:self.post type:LCCCountTypeLike block:^(NSArray *users) {
        
        [self.activityIndicator decreaseActivity];
        if (users)
        {
            self.titleCell.likeCount = users.count;
            if (![self.post.user isMe])
            {
                BOOL liked = [[CommunityModel sharedInstance] isCurrentUserInArray:users];
                if (liked)
                {
                    [self.titleCell likeIt];
                }
                else
                {
                    self.titleCell.likeButton.enabled = YES;
                }
            }
        }
        
    }];
    
    if (self.post.type == LCCPostTypeProgram)
    {
        // Downloads
        [self.activityIndicator increaseActivity];
        [[CommunityModel sharedInstance] fetchCountForPost:self.post type:LCCCountTypeDownload block:^(NSArray *users) {
            
            [self.activityIndicator decreaseActivity];
            if (users)
            {
                self.titleCell.downloadCount = users.count;
            }
            
        }];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
    }
}

- (IBAction)onGetProgramTapped:(id)sender
{
    [self onGetProgramTappedWithPost:self.post];
}

- (IBAction)onShareTapped:(id)sender
{
    [self showConfirmAlertWithTitle:@"Do you really want to share this?" message:nil block:^{
        [self share];
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
    post.sharedPost = self.post;
    
    [self.activityIndicator increaseActivity];
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        [self.activityIndicator decreaseActivity];
        if (succeeded)
        {
            [[CommunityModel sharedInstance] onPostedWithDate:post.createdAt];
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
        LCCComment *comment = [LCCComment object];
        comment.user = (LCCUser *)[PFUser currentUser];
        comment.post = self.post;
        comment.text = commentText;
        
        UIButton *button = (UIButton *)sender;
        
        [self.activityIndicator increaseActivity];
        button.enabled = NO;
        
        [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            [self.activityIndicator decreaseActivity];
            button.enabled = YES;
            
            if (succeeded)
            {
                [self.comments addObject:comment];
                if (self.comments.count == 1)
                {
                    // first comment (need to refresh headers)
                    [self.tableView reloadData];
                }
                else
                {
                    // later comment
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                [self.writeCommentCell reset];
            }
            else if (error)
            {
                [self showAlertWithTitle:@"Could not send comment." message:error.userInfo[@"error"] block:nil];
            }
            
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
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(comment.user ? @"CommentCell" : @"GuestCommentCell") forIndexPath:indexPath];
        cell.textLabel.text = comment.text;
        NSString *name = (comment.user ? comment.user.username : @"Guest");
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", name, [NSDateFormatter localizedStringFromDate:comment.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
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
        default:
            break;
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"CommentAuthor"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        LCCComment *comment = self.comments[indexPath.row];
        LCCUser *user = comment.user;
        CommDetailViewController *vc = segue.destinationViewController;
        [vc setUser:user mode:CommListModeProfile];
    }
}


@end

@interface ProgramTitleCell()
@property (weak, nonatomic) IBOutlet UIImageView *programImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *programDetailLabel;
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
        self.titleLabel.text = post.title;
        self.programDetailLabel.text = post.detail;
        
        self.dateLabel.text = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
        
        self.shareButton.enabled = ![post.user isMe];
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

@implementation WriteCommentCell

- (void)reset
{
    self.textView.text = @"";
}

@end
