//
//  Project.h
//  Pixels
//
//  Created by Timo Kloss on 30/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Project : NSManagedObject

@property (nonatomic, retain) NSData * iconData;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * sourceCode;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * scale;

@end
