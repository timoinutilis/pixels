//
//  Project+CoreDataProperties.h
//  Pixels
//
//  Created by Timo Kloss on 3/11/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Project.h"

NS_ASSUME_NONNULL_BEGIN

@interface Project (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createdAt;
@property (nullable, nonatomic, retain) NSData *iconData;
@property (nullable, nonatomic, retain) NSNumber *isDefault;
@property (nullable, nonatomic, retain) NSNumber *isFolder;
@property (nullable, nonatomic, retain) NSNumber *isIconLocked;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *postId;
@property (nullable, nonatomic, retain) NSString *programDescription;
@property (nullable, nonatomic, retain) NSNumber *programType;
@property (nullable, nonatomic, retain) NSString *sourceCode;
@property (nullable, nonatomic, retain) NSNumber *order;
@property (nullable, nonatomic, retain) NSSet<Project *> *children;
@property (nullable, nonatomic, retain) Project *parent;

@end

@interface Project (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(Project *)value;
- (void)removeChildrenObject:(Project *)value;
- (void)addChildren:(NSSet<Project *> *)values;
- (void)removeChildren:(NSSet<Project *> *)values;

@end

NS_ASSUME_NONNULL_END
