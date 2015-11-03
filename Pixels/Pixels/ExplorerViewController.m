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
#import "AppController.h"
#import "CoachMarkView.h"
#import "UIViewController+LowResCoder.h"
#import "UICollectionView+Draggable.h"
#import "DraggableCollectionViewFlowLayout.h"

NSString *const CoachMarkIDAdd = @"CoachMarkIDAdd";

@interface ExplorerViewController ()  <UICollectionViewDelegate, UICollectionViewDataSource_Draggable, UITraitEnvironment>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property NSMutableArray *projects;
@property Project *addedProject;
@property Project *lastSelectedProject;

@end

@implementation ExplorerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addProjectItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddProjectTapped:)];
    UIBarButtonItem *addFolderItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddFolderTapped:)];
    
    self.navigationItem.rightBarButtonItems = @[addProjectItem, addFolderItem];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.draggable = YES;
    
    DraggableCollectionViewFlowLayout *layout = (DraggableCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(140, 140);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    
    if (self.folder)
    {
        self.title = self.folder.name;
    }
    
    [self loadProjects];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddProject:) name:ModelManagerDidAddProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMoveProject:) name:ModelManagerDidMoveProjectNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerDidAddProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerDidMoveProjectNotification object:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
    {
        self.navigationItem.backBarButtonItem = nil;
    }
    else
    {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.lastSelectedProject)
    {
        if (self.lastSelectedProject.isDeleted || !self.lastSelectedProject.managedObjectContext)
        {
            [self loadProjects];
            self.addedProject = nil;
        }
        else
        {
            [self.collectionView reloadData];
        }
        self.lastSelectedProject = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.collectionView flashScrollIndicators];
    [self showAddedProject];
    
    AppController *app = [AppController sharedController];
    if (app.numProgramsOpened >= 3)
    {
        if ([app isUnshownInfoID:CoachMarkIDAdd])
        {
            [app onShowInfoID:CoachMarkIDAdd];
            CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Tap the Plus button to create your first own program!" complete:nil];
            [coachMark setTargetNavBar:self.navigationController.navigationBar itemIndex:0];
            [coachMark show];
        }
    }
    
    // Show stored error
    NSString *lastError = [[AppController sharedController] popStoredError];
    if (lastError)
    {
        [self showAlertWithTitle:@"Sorry, there was an error" message:lastError block:nil];
    }
}

- (void)loadProjects
{
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];

    if (self.folder)
    {
        // user projects in folder
        
        self.projects = [NSMutableArray arrayWithArray:self.folder.children.allObjects];
        [self.projects sortUsingDescriptors:sortDescriptors];
        [self.projects insertObject:[NSNull null] atIndex:0];
    }
    else
    {
        // root folder
        
        NSError *error;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Project"];
        request.predicate = [NSPredicate predicateWithFormat:@"parent == nil"];
        request.sortDescriptors = sortDescriptors;
        
        // default projects
        NSArray *defaultProjects = [[ModelManager sharedManager].temporaryContext executeFetchRequest:request error:&error];
        self.projects = [NSMutableArray arrayWithArray:defaultProjects];
        
        // user projects
        NSArray *userProjects = [[ModelManager sharedManager].managedObjectContext executeFetchRequest:request error:&error];
        [self.projects addObjectsFromArray:userProjects];
    }
    
    [self.collectionView reloadData];
}

- (void)didAddProject:(NSNotification *)notification
{
    Project *project = notification.userInfo[@"project"];
    if (project.parent == self.folder)
    {
        self.addedProject = project;
    }
}

- (void)didMoveProject:(NSNotification *)notification
{
    Project *project = notification.userInfo[@"project"];
    if (project.parent == self.folder)
    {
        [self.projects addObject:project];
        [self.collectionView reloadData];
    }
}

- (void)onAddProjectTapped:(id)sender
{
    [[AppController sharedController] onShowInfoID:CoachMarkIDAdd];
    
    [[ModelManager sharedManager] createNewProjectInFolder:self.folder];
    [self showAddedProject];
}

- (void)onAddFolderTapped:(id)sender
{
    [[ModelManager sharedManager] createNewFolderInFolder:self.folder];
    [self showAddedProject];
}

- (void)showAddedProject
{
    if (self.addedProject)
    {
        [self.projects addObject:self.addedProject];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.projects.count - 1 inSection:0];
        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        
        self.addedProject = nil;
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

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Project *project = self.projects[fromIndexPath.item];
    [self.projects removeObjectAtIndex:fromIndexPath.item];
    [self.projects insertObject:project atIndex:toIndexPath.item];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = self.projects[indexPath.item];
    return (id)project != [NSNull null];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Project *project1 = self.projects[indexPath.item];
    Project *project2 = self.projects[toIndexPath.item];
    return !project1.isDefault.boolValue && (id)project2 != [NSNull null] && !project2.isDefault.boolValue;
}

- (void)collectionView:(UICollectionView *)collectionView didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath intoItemAtIndexPath:(NSIndexPath *)intoIndexPath
{
    Project *project1 = self.projects[indexPath.item];
    Project *project2 = self.projects[intoIndexPath.item];
    return !project1.isDefault.boolValue
        && ((id)project2 == [NSNull null] || (project2.isFolder.boolValue && !project2.isDefault.boolValue));
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath intoItemAtIndexPath:(NSIndexPath *)intoIndexPath
{
    Project *project = self.projects[fromIndexPath.item];
    Project *folder = self.projects[intoIndexPath.item];
    [self.projects removeObjectAtIndex:fromIndexPath.item];
    if ((id)folder == [NSNull null])
    {
        [[ModelManager sharedManager] moveProject:project toFolder:self.folder.parent];
    }
    else
    {
        [[ModelManager sharedManager] moveProject:project toFolder:folder];
    }
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = self.projects[indexPath.item];
    if ((id)project == [NSNull null])
    {
        // parent folder
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        self.lastSelectedProject = project;
        
        if (project.isFolder.boolValue)
        {
            ExplorerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ExplorerView"];
            vc.folder = project;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else
        {
            [[AppController sharedController] onProgramOpened];
            
            EditorViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"EditorView"];
            vc.project = project;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

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
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@end

@implementation ExplorerProjectCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    CALayer *imageLayer = self.previewImageView.layer;
    imageLayer.cornerRadius = 20;
    imageLayer.masksToBounds = YES;
}

- (void)setProject:(Project *)project
{
    _project = project;
    [self update];
}

- (void)update
{
    if ((id)self.project == [NSNull null])
    {
        // parent folder
        self.nameLabel.text = @"PARENT FOLDER";
        self.starImageView.hidden = YES;
        self.previewImageView.image = [UIImage imageNamed:@"icon_project"];
    }
    else
    {
        self.nameLabel.text = self.project.name.uppercaseString;
        self.starImageView.hidden = !self.project.isDefault.boolValue;
        if (self.project.iconData)
        {
            UIImage *image = [UIImage imageWithData:self.project.iconData];
            self.previewImageView.image = image;
        }
        else
        {
            self.previewImageView.image = [UIImage imageNamed:@"icon_project"];
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    self.previewImageView.alpha = highlighted ? 0.5 : 1.0;
}

@end