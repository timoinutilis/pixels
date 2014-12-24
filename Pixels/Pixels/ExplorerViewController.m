//
//  ProjectExplorerViewController.m
//  Pixels
//
//  Created by Timo Kloss on 28/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "ExplorerViewController.h"
#import "ModelManager.h"
#import "EditorViewController.h"

@interface ExplorerViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property NSMutableArray *projects;

@end

@implementation ExplorerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
//    [self loadProjects];
}

- (void)viewWillAppear:(BOOL)animated
{
/*    NSArray *indexPaths = self.collectionView.indexPathsForSelectedItems;
    if (indexPaths.count > 0)
    {
        ExplorerProjectCell *cell = (ExplorerProjectCell *)[self.collectionView cellForItemAtIndexPath:indexPaths[0]];
        [cell update];
    }*/
    [self loadProjects];
}

- (void)loadProjects
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Project"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
    NSArray *projects = [[ModelManager sharedManager].managedObjectContext executeFetchRequest:request error:&error];
    self.projects = [NSMutableArray arrayWithArray:projects];
    [self.collectionView reloadData];
}

- (IBAction)onHelpTapped:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UIViewController *vc = (UIViewController *)[storyboard instantiateInitialViewController];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)onAddTapped:(id)sender
{
    Project *project = [[ModelManager sharedManager] createNewProject];
    
    [self.projects addObject:project];
    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.projects.count - 1 inSection:0]]];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Editor"])
    {
        EditorViewController *vc = segue.destinationViewController;
        NSArray *indexPaths = self.collectionView.indexPathsForSelectedItems;
        ExplorerProjectCell *cell = (ExplorerProjectCell *)[self.collectionView cellForItemAtIndexPath:indexPaths[0]];
        vc.project = cell.project;
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.projects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ExplorerProjectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProjectCell" forIndexPath:indexPath];
    cell.project = self.projects[indexPath.item];
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	
}
*/

@end


@interface ExplorerProjectCell ()
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@end

@implementation ExplorerProjectCell

- (void)awakeFromNib
{
    self.nameLabel.text = @"Project Name";
}

- (void)setProject:(Project *)project
{
    _project = project;
    [self update];
}

- (void)update
{
    self.nameLabel.text = self.project.name;
    if (self.project.iconData)
    {
        UIImage *image = [UIImage imageWithData:self.project.iconData];
        self.previewImageView.image = image;
    }
    else
    {
        self.previewImageView.image = [UIImage imageNamed:@"dummy_project_icon"];
    }
}

@end