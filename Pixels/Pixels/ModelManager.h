//
//  ModelManager.h
//  Pixels
//
//  Created by Timo Kloss on 29/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Project.h"

extern NSString *const ModelManagerWillSaveDataNotification;
extern NSString *const ModelManagerDidAddProjectNotification;

@interface ModelManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *temporaryContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (ModelManager *)sharedManager;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void)createDefaultProjects;
- (Project *)createNewProject;
- (void)deleteProject:(Project *)project;
- (Project *)duplicateProject:(Project *)project;

@end
