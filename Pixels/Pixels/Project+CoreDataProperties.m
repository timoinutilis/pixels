//
//  Project+CoreDataProperties.m
//  Pixels
//
//  Created by Timo Kloss on 2/11/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Project+CoreDataProperties.h"

@implementation Project (CoreDataProperties)

@dynamic createdAt;
@dynamic iconData;
@dynamic isDefault;
@dynamic name;
@dynamic postId;
@dynamic sourceCode;
@dynamic isFolder;
@dynamic programType;
@dynamic programDescription;
@dynamic isIconLocked;
@dynamic parent;
@dynamic children;

@end
