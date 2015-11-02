//
//  ModelManager.m
//  Pixels
//
//  Created by Timo Kloss on 29/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "ModelManager.h"
#import "AppController.h"

NSString *const ModelManagerWillSaveDataNotification = @"ModelManagerWillSaveDataNotification";
NSString *const ModelManagerDidAddProjectNotification = @"ModelManagerDidAddProjectNotification";

@interface ModelManager ()


@end

@implementation ModelManager

+ (ModelManager *)sharedManager
{
    static ModelManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize temporaryContext = _temporaryContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory
{
    // The directory the application uses to store the Core Data store file. This code uses a directory named "LowRes-Coder" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel
{
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LowRes-Coder.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        NSLog(@"Core Data error: %@", error);
        [[AppController sharedController] storeError:error message:@"Core Data persistentStoreCoordinator"];
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext
{
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

- (NSManagedObjectContext *)temporaryContext
{
    if (!_temporaryContext)
    {
        NSError *error = nil;
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
        if (error)
        {
            NSLog(@"Core Data temporaryContext error: %@", error);
            [[AppController sharedController] storeError:error message:@"Core Data temporaryContext"];
        }
        else
        {
            _temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_temporaryContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return _temporaryContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    [self.managedObjectContext performBlockAndWait:^{
        
        self.debugSaveCount = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:ModelManagerWillSaveDataNotification object:self];
        
        if (self.debugSaveCount > 1)
        {
            [[AppController sharedController] storeError:[NSError errorWithDomain:@"LowResCoder" code:1 userInfo:nil]
                                                 message:[NSString stringWithFormat:@"DebugSaveCount = %ld", (long)self.debugSaveCount]];
        }
        
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges])
        {
            if ([self.managedObjectContext save:&error])
            {
                // saved!
            }
            else
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                [[AppController sharedController] storeError:error message:@"Core Data save"];
            }
        }
        
    }];
}

#pragma mark - stuff

- (void)createDefaultProjects
{
    NSError *error;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"DefaultProjects" withExtension:@"json" subdirectory:@"Default Projects"];
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    NSArray *jsonProjects = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    for (NSDictionary *jsonProject in jsonProjects)
    {
        Project *project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.temporaryContext];
        project.isDefault = @YES;
        project.name = jsonProject[@"name"];
        project.createdAt = [NSDate date];
        project.sourceCode = jsonProject[@"sourceCode"];
        
        NSString *iconName = jsonProject[@"icon"];
        NSURL *iconUrl = [[NSBundle mainBundle] URLForResource:iconName withExtension:@"png" subdirectory:@"Default Projects"];
        project.iconData = [NSData dataWithContentsOfURL:iconUrl];
    }
}

- (Project *)createNewProject
{
    Project *project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
    project.name = @"Unnamed Program";
    project.createdAt = [NSDate date];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ModelManagerDidAddProjectNotification object:self userInfo:@{@"project": project}];
    
    return project;
}

- (Project *)createNewFolder
{
    Project *project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
    project.name = @"Unnamed Folder";
    project.createdAt = [NSDate date];
    project.isFolder = @YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ModelManagerDidAddProjectNotification object:self userInfo:@{@"project": project}];
    
    return project;
}

- (void)deleteProject:(Project *)project
{
    [self.managedObjectContext deleteObject:project];
}

- (Project *)duplicateProject:(Project *)project sourceCode:(NSString *)sourceCode
{
    Project *newProject = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
    newProject.name = [NSString stringWithFormat:@"Copy of %@", project.name];
    newProject.iconData = project.iconData;
    newProject.sourceCode = sourceCode ? sourceCode : project.sourceCode;
    newProject.createdAt = [NSDate date];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ModelManagerDidAddProjectNotification object:self userInfo:@{@"project": newProject}];
    
    return newProject;
}

- (BOOL)hasProjectWithPostId:(NSString *)postId
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Project"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"postId == %@", postId];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    return (objects.count > 0);
}

@end
