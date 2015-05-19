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
#import "HelpTextViewController.h"
#import "AppController.h"
#import "CoachMarkView.h"
#import "AppStyle.h"

NSString *const ExplorerRefreshAddedProjectNotification = @"ExplorerRefreshAddedProjectNotification";

NSString *const CoachMarkIDAdd = @"CoachMarkIDAdd";

@interface ExplorerViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *getButton;

@property NSMutableArray *projects;
@property Project *addedProject;
@property Project *lastSelectedProject;

@end

@implementation ExplorerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppStyle styleNavigationController:self.navigationController];
    self.collectionView.backgroundColor = [AppStyle brightColor];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddTapped:)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(onHelpTapped:)];
    self.navigationItem.rightBarButtonItems = @[addButton, helpButton];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [[ModelManager sharedManager] createDefaultProjects];
    [self loadProjects];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddProject:) name:ModelManagerDidAddProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAddedProject:) name:ExplorerRefreshAddedProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsChanged:) name:NewsNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerDidAddProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ExplorerRefreshAddedProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NewsNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.lastSelectedProject)
    {
        if (self.lastSelectedProject.isDeleted || !self.lastSelectedProject.managedObjectContext)
        {
            [self loadProjects];
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
            [[CoachMarkView create] showWithText:@"Tap the Plus button to create your first own program!" image:@"coach_add" container:self.navigationController.view complete:nil];
        }
    }
    
    [self updateGetButton];
}

- (void)updateGetButton
{
    NSInteger numNews = [AppController sharedController].numNews;
    if (numNews > 0)
    {
        self.getButton.title = [NSString stringWithFormat:@"Get More (%ld)", (long)numNews];
    }
    else
    {
        self.getButton.title = @"Get More";
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

- (void)refreshAddedProject:(NSNotification *)notification
{
    [self showAddedProject];
}

- (void)newsChanged:(NSNotification *)notification
{
    [self updateGetButton];
}

- (void)onHelpTapped:(id)sender
{
    [HelpTextViewController showHelpWithParent:self];
}

- (void)onAddTapped:(id)sender
{
    [[AppController sharedController] onShowInfoID:CoachMarkIDAdd];
    
    [[ModelManager sharedManager] createNewProject];
    [self showAddedProject];
}

- (IBAction)onCommunityTapped:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    UIViewController *vc = (UIViewController *)[storyboard instantiateInitialViewController];
    
    [self presentViewController:vc animated:YES completion:nil];
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
    else if ([segue.identifier isEqualToString:@"About"])
    {
        UIViewController *vc = segue.destinationViewController;
        vc.popoverPresentationController.backgroundColor = self.navigationController.navigationBar.barTintColor;
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
    self.nameLabel.text = @"Project Name";
    self.nameLabel.textColor = [AppStyle darkColor];
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