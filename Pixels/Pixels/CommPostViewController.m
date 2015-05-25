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

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagSourceCode,
    CellTagPostAuthor
};

@interface CommPostViewController ()
@property LCCPost *post;
@property NSMutableArray *comments;
@property CommPostMode mode;
@property WriteCommentCell *writeCommentCell;
@end

@implementation CommPostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.comments = [NSMutableArray array];
    self.writeCommentCell = [self.tableView dequeueReusableCellWithIdentifier:@"WriteCommentCell"];
}

- (void)setPost:(LCCPost *)post mode:(CommPostMode)mode
{
    self.post = post;
    self.mode = mode;
    self.title = post.title;
    [self.tableView reloadData];
    
    [self loadComments];
}

- (void)loadComments
{
    PFQuery *query = [PFQuery queryWithClassName:[LCCComment parseClassName]];
    [query whereKey:@"post" equalTo:self.post];
    [query includeKey:@"user"];
    [query orderByAscending:@"createdAt"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.comments = [NSMutableArray arrayWithArray:objects];
        [self.tableView reloadData];
    }];
}

- (IBAction)onSendCommentTapped:(id)sender
{
    LCCComment *comment = [LCCComment object];
    comment.user = (LCCUser *)[PFUser currentUser];
    comment.post = self.post;
    comment.text = self.writeCommentCell.textView.text;
    
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded)
        {
            [self.comments addObject:comment];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
        return 3;
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
        return @"Program";
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
            ProgramTitleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProgramTitleCell" forIndexPath:indexPath];
            cell.post = self.post;
            return cell;
        }
        else if (indexPath.row == 1)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = @"Source Code";
            cell.tag = CellTagSourceCode;
            return cell;
        }
        else if (indexPath.row == 2)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"By %@", self.post.user.username];
            cell.tag = CellTagPostAuthor;
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.rowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag)
    {
        case CellTagSourceCode: {
            [self performSegueWithIdentifier:@"SourceCode" sender:self];
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
@end

@implementation ProgramTitleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    CALayer *layer = self.programImage.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 6;
    layer.borderWidth = 1;
    layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
}

- (void)setPost:(LCCPost *)post
{
    _post = post;
    [self.programImage sd_setImageWithURL:[NSURL URLWithString:post.image.url]];
    self.titleLabel.text = post.title;
    self.programDetailLabel.text = post.detail;
}

@end

@implementation WriteCommentCell

- (void)reset
{
    self.textView.text = @"";
}

@end
