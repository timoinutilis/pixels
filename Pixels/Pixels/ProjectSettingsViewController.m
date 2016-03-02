//
//  ProjectSettingsViewController.m
//  Pixels
//
//  Created by Timo Kloss on 1/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "ProjectSettingsViewController.h"
#import "ModelManager.h"
#import "TextFieldTableViewCell.h"

typedef NS_ENUM(NSInteger, Section) {
    SectionName,
    SectionIconMode,
    SectionIconSelector,
    Section_count
};

@interface ProjectSettingsViewController()
@property BOOL updateIconAutomatically;
@end

@implementation ProjectSettingsViewController

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionIconSelector)
    {
        return 88;
    }
    return tableView.rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return Section_count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case SectionName:
            return 1;
            
        case SectionIconMode:
            return 2;
            
        case SectionIconSelector:
            return 1;
    }
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case SectionName:
            return @"Name";
            
        case SectionIconMode:
            return @"Icon Mode";
            
        case SectionIconSelector:
            return @"Choose a Snapshot";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case SectionName: {
            TextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextField" forIndexPath:indexPath];
            cell.textField.text = self.project.name;
            return cell;
        }
        
        case SectionIconMode: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Basic" forIndexPath:indexPath];
            if (indexPath.row == 0)
            {
                cell.textLabel.text = @"Update Automatically";
                cell.accessoryType = self.updateIconAutomatically ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            else if (indexPath.row == 1)
            {
                cell.textLabel.text = @"Choose from Snapshots";
                cell.accessoryType = !self.updateIconAutomatically ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            return cell;
        }
            
        case SectionIconSelector:
        {
            IconSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IconSelector" forIndexPath:indexPath];
            UIImage *image = [UIImage imageWithData:self.project.iconData];
            cell.images = @[image];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionIconMode)
    {
        self.updateIconAutomatically = (indexPath.row == 0);
        [self updateIconModeCells];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)updateIconModeCells
{
    UITableViewCell *cell;
    
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SectionIconMode]];
    cell.accessoryType = self.updateIconAutomatically ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:SectionIconMode]];
    cell.accessoryType = !self.updateIconAutomatically ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

@end


@interface IconSelectorTableViewCell() <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@end

@implementation IconSelectorTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
}

- (void)setImages:(NSArray<UIImage *> *)images
{
    _images = images;
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IconSelectorImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Image" forIndexPath:indexPath];
    cell.image = self.images[indexPath.item];
    return cell;
}

@end


@interface IconSelectorImageCollectionViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation IconSelectorImageCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    CALayer *layer = self.imageView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 6;
    layer.borderWidth = 0.5;
    layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
}

@end
