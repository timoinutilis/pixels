//
//  GORMenuTableViewController.m
//  Urban Ballr
//
//  Created by Timo Kloss on 11/11/14.
//  Copyright (c) 2014 Gorilla Arm Ltd. All rights reserved.
//

#import "GORMenuTableViewController.h"

@interface GORMenuTableViewController ()
@property NSMutableArray *sections;
@property CGFloat verticalSpace;
@property NSMutableArray *spaceCells;
@end

@implementation GORMenuTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sections = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateSpace];
}

- (void)addCell:(UITableViewCell *)cell
{
    NSInteger section = self.sections.count;
    if (section > 0)
    {
        section--;
    }
    [self addCell:cell section:section];
    
    if ([cell isKindOfClass:[GORSpaceTableViewCell class]])
    {
        if (!self.spaceCells)
        {
            self.spaceCells = [NSMutableArray array];
        }
        [self.spaceCells addObject:cell];
    }
}

- (void)addCell:(UITableViewCell *)cell section:(NSInteger)section
{
    while (section >= self.sections.count)
    {
        [self.sections addObject:[[GORMenuSection alloc] init]];
    }
    GORMenuSection *sectionObj = self.sections[section];
    [sectionObj.cells addObject:cell];
}

- (void)removeCellWithReuseIdentifier:(NSString *)reuseIdentifier section:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    for (int i = 0; i < sectionObj.cells.count; i++)
    {
        UITableViewCell *cell = sectionObj.cells[i];
        if ([cell.reuseIdentifier isEqualToString:reuseIdentifier])
        {
            [sectionObj.cells removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)setHeader:(UIView *)view section:(NSInteger)section
{
    while (section >= self.sections.count)
    {
        [self.sections addObject:[[GORMenuSection alloc] init]];
    }
    GORMenuSection *sectionObj = self.sections[section];
    sectionObj.header = view;
}

- (void)updateSpace
{
    self.verticalSpace = 0.0;
    if (self.spaceCells)
    {
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        self.verticalSpace = MAX(0.0, self.tableView.frame.size.height - self.tableView.contentSize.height);
        [self.tableView reloadData];
    }
}

- (UITableViewCell *)cellWithReuseIdentifier:(NSString *)reuseIdentifier section:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    for (int i = 0; i < sectionObj.cells.count; i++)
    {
        UITableViewCell *cell = sectionObj.cells[i];
        if ([cell.reuseIdentifier isEqualToString:reuseIdentifier])
        {
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    return sectionObj.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GORMenuSection *sectionObj = self.sections[indexPath.section];
    return sectionObj.cells[indexPath.row];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    return sectionObj.header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GORMenuSection *sectionObj = self.sections[indexPath.section];
    UITableViewCell *cell = sectionObj.cells[indexPath.row];
    
    if (self.spaceCells && [cell isKindOfClass:[GORSpaceTableViewCell class]])
    {
        return floorf(self.verticalSpace / self.spaceCells.count);
    }
    
    if (![self.tableView respondsToSelector:@selector(separatorEffect)]) // iOS 8 check
    {
        // iOS 7 code
        [cell layoutSubviews];
        CGSize size = [cell sizeThatFits:self.tableView.frame.size];
        return size.height;
    }
    
    // iOS 8 code
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    if (sectionObj.header)
    {
        CGSize size = [sectionObj.header sizeThatFits:self.tableView.frame.size];
        return size.height;
    }
    return 0;
}

@end


@implementation GORSpaceTableViewCell

- (instancetype)init
{
    if (self = [super init])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

@end

@implementation GORMenuSection

- (instancetype)init
{
    if (self = [super init])
    {
        self.cells = [NSMutableArray array];
    }
    return self;
}

@end
