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

@interface HelpTableViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property HelpTextViewController *textViewController;
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
    UINavigationController *nav = (UINavigationController *)self.presentingViewController;
    self.textViewController = (HelpTextViewController *)(nav.topViewController);
    self.helpContent = self.textViewController.helpContent;
}

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
    self.textViewController.chapter = chapter.htmlChapter;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
