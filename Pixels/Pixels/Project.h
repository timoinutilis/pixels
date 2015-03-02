//
//  Project.h
//  Pixels
//
//  Created by Timo Kloss on 2/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Project : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSData * iconData;
@property (nonatomic, retain) NSNumber * isDefault;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * scale;
@property (nonatomic, retain) NSString * sourceCode;

@end
