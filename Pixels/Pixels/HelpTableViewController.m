//
//  HelpTableViewController.m
//  Pixels
//
//  Created by Timo Kloss on 29/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "HelpTableViewController.h"
#import "HelpTextViewController.h"
#import "HelpContent.h"
#import "HelpSplitViewController.h"

@interface HelpTableViewController ()
@property HelpContent *helpContent;
@end

@implementation HelpTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    HelpSplitViewController *helpVC = (HelpSplitViewController *)self.splitViewController;
    self.helpContent = helpVC.helpContent;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.helpContent.chapters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HelpChapter *chapter = self.helpContent.chapters[indexPath.row];
    NSString *cellIdentifier;
    if (chapter.level == 0)
    {
        cellIdentifier = @"ChapterCell";
    }
    else if (chapter.level == 1)
    {
        cellIdentifier = @"SubchapterCell";
    }
    else
    {
        cellIdentifier = @"CommandCell";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = chapter.title;
    cell.indentationLevel = chapter.level;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HelpChapter *chapter = self.helpContent.chapters[indexPath.row];
    HelpSplitViewController *helpVC = (HelpSplitViewController *)self.splitViewController;
    [self.splitViewController showDetailViewController:helpVC.detailNavigationController sender:self];
    
    HelpTextViewController *textViewController = (HelpTextViewController *)helpVC.detailNavigationController.topViewController;
    textViewController.chapter = chapter.htmlChapter;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryOverlay)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        }];
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
    }
}

@end
