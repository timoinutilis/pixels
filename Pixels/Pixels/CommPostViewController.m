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
#import "UIViewController+CommUtils.h"

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagSourceCode,
    CellTagPostAuthor
};

@interface CommPostViewController ()
@property LCCPost *post;
@property NSMutableArray *comments;
@property CommPostMode mode;
@property ProgramTitleCell *titleCell;
@property WriteCommentCell *writeCommentCell;
@end

@implementation CommPostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44;
    
    self.writeCommentCell = [self.tableView dequeueReusableCellWithIdentifier:@"WriteCommentCell"];
    
    [self updateView];
}

- (void)setPost:(LCCPost *)post mode:(CommPostMode)mode
{
    self.post = post;
    self.mode = mode;
}

- (void)updateView
{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.post.title style:UIBarButtonItemStylePlain target:nil action:nil];
    self.title = self.post.title;
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:(self.post.type == LCCPostTypeProgram ? @"ProgramTitleCell" : @"StatusTitleCell")];
    self.titleCell.post = self.post;
    [self loadAll];
}

- (void)loadAll
{
    [self loadComments];
    [self loadProgram];
    [self loadCounters];
}

- (void)loadComments
{
    self.comments = [NSMutableArray array];
    
    PFQuery *query = [PFQuery queryWithClassName:[LCCComment parseClassName]];
    [query whereKey:@"post" equalTo:self.post];
    [query includeKey:@"user"];
    [query orderByAscending:@"createdAt"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects)
        {
            self.comments = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }
        else if (error)
        {
            NSLog(@"Error: %@", error.description);
        }
        
    }];
}

- (void)loadProgram
{
    if ([self.post.program isDataAvailable])
    {
        self.titleCell.getProgramButton.enabled = YES;
    }
    else
    {
        [self.post.program fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            if (object)
            {
                self.titleCell.getProgramButton.enabled = YES;
            }
            else if (error)
            {
                NSLog(@"Error: %@", error.description);
            }
            
        }];
    }
}

- (void)loadCounters
{
    // Likes
    [[CommunityModel sharedInstance] fetchCountForPost:self.post type:LCCCountTypeLike block:^(NSArray *users) {
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
    
    // Downloads
    [[CommunityModel sharedInstance] fetchCountForPost:self.post type:LCCCountTypeDownload block:^(NSArray *users) {
        if (users)
        {
            self.titleCell.downloadCount = users.count;
        }
    }];
}

- (IBAction)onLikeTapped:(id)sender
{
    [[CommunityModel sharedInstance] countPost:self.post type:LCCCountTypeLike];
    self.titleCell.likeCount++;
    [self.titleCell likeIt];
}

- (IBAction)onGetProgramTapped:(id)sender
{
    [self addProgramOfPost:self.post];
}

- (IBAction)onSendCommentTapped:(id)sender
{
    if (self.writeCommentCell.textView.text.length > 0)
    {
        [self.view endEditing:YES];
        
        LCCComment *comment = [LCCComment object];
        comment.user = (LCCUser *)[PFUser currentUser];
        comment.post = self.post;
        comment.text = self.writeCommentCell.textView.text;
        
        [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
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
            else
            {
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Could not send comment" message:@"Please try again later!" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
    {
        return (self.post.type == LCCPostTypeProgram ? 3 : 2);
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
        return (self.post.type == LCCPostTypeProgram ? @"Program" : @"Status Update");
    }
    else if (section == 1)
    {
        return (self.comments.count > 0) ? @"Comments" : @"No Comments Yet";
    }
    else if (section == 2)
    {
        return @"Write a Comment";
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
            cell.textLabel.text = [NSString stringWithFormat:@"By %@", self.post.user.username];
            cell.tag = CellTagPostAuthor;
            return cell;
        }
        else if (indexPath.row == 2)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Source Code";
            cell.tag = CellTagSourceCode;
            return cell;
        }
    }
    else if (indexPath.section == 1)
    {
        LCCComment *comment = self.comments[indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
        cell.textLabel.text = comment.text;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", comment.user.username, [NSDateFormatter localizedStringFromDate:comment.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
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
            if ([self.post isDataAvailable])
            {
                [self performSegueWithIdentifier:@"SourceCode" sender:self];
            }
            break;
        }
        case CellTagPostAuthor: {
            [self performSegueWithIdentifier:@"PostAuthor" sender:self];
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
    if ([segue.identifier isEqualToString:@"SourceCode"])
    {
        CommSourceCodeViewController *vc = segue.destinationViewController;
        vc.post = self.post;
    }
    else if ([segue.identifier isEqualToString:@"PostAuthor"])
    {
        CommDetailViewController *vc = segue.destinationViewController;
        [vc setUser:self.post.user mode:CommListModeProfile];
    }
    else if ([segue.identifier isEqualToString:@"CommentAuthor"])
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
        layer.borderWidth = 1;
        layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
    }
    
    if (self.getProgramButton)
    {
        self.getProgramButton.enabled = NO;
    }
    
    self.likeButton.enabled = NO;
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
        
        NSString *date = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
        if (post.category == LCCPostCategoryStatus)
        {
            self.dateLabel.text = date;
        }
        else
        {
            self.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", [post categoryString], date];
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

@implementation WriteCommentCell

- (void)reset
{
    self.textView.text = @"";
}

@end
