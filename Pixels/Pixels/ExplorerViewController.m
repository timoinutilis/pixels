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

NSString *const CoachMarkIDAdd = @"CoachMarkIDAdd";

@interface ExplorerViewController () <UITraitEnvironment>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property NSMutableArray *projects;
@property Project *addedProject;
@property Project *lastSelectedProject;

@end

@implementation ExplorerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddTapped:)];
    
    self.navigationItem.rightBarButtonItems = @[addItem];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [[ModelManager sharedManager] createDefaultProjects];
    [self loadProjects];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddProject:) name:ModelManagerDidAddProjectNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerDidAddProjectNotification object:nil];
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
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Project"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
    
    // default projects
    NSArray *defaultProjects = [[ModelManager sharedManager].temporaryContext executeFetchRequest:request error:&error];
    self.projects = [NSMutableArray arrayWithArray:defaultProjects];
    
    // user projects
    NSArray *userProjects = [[ModelManager sharedManager].managedObjectContext executeFetchRequest:request error:&error];
    [self.projects addObjectsFromArray:userProjects];
    
    [self.collectionView reloadData];
}

- (void)didAddProject:(NSNotification *)notification
{
    self.addedProject = notification.userInfo[@"project"];
}

- (void)onAddTapped:(id)sender
{
    [[AppController sharedController] onShowInfoID:CoachMarkIDAdd];
    
    [[ModelManager sharedManager] createNewProject];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Editor"])
    {
        EditorViewController *vc = segue.destinationViewController;
        NSArray *indexPaths = self.collectionView.indexPathsForSelectedItems;
        ExplorerProjectCell *cell = (ExplorerProjectCell *)[self.collectionView cellForItemAtIndexPath:indexPaths[0]];
        vc.project = cell.project;
        
        self.lastSelectedProject = cell.project;
        
        [[AppController sharedController] onProgramOpened];
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
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@end

@implementation ExplorerProjectCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.nameLabel.text = @"Project Name";
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

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    self.previewImageView.alpha = highlighted ? 0.5 : 1.0;
}

@end