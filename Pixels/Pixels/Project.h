//
//  Project.h
//  Pixels
//
//  Created by Timo Kloss on 2/11/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, FolderType) {
    FolderTypeNone,
    FolderTypeNormal,
    FolderTypeRoot
};

NS_ASSUME_NONNULL_BEGIN

@interface Project : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "Project+CoreDataProperties.h"
