//
//  UITableView+Parse.m
//  Pixels
//
//  Created by Timo Kloss on 23/2/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "UITableView+Parse.h"
#import <Parse/Parse.h>

@implementation UITableView (Parse)

- (void)reloadDataAnimatedWithOldArray:(NSArray *)oldArray newArray:(NSArray *)newArray inSection:(NSInteger)section offset:(NSInteger)offset
{
    NSMutableSet *oldSet = [NSMutableSet setWithCapacity:oldArray.count];
    NSMutableSet *newSet = [NSMutableSet setWithCapacity:newArray.count];
    
    for (PFObject *object in oldArray)
    {
        [oldSet addObject:object.objectId];
    }
    for (PFObject *object in newArray)
    {
        [newSet addObject:object.objectId];
    }
    
    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
    NSMutableArray *indexPathsToAdd = [NSMutableArray array];
    for (int i = 0; i < oldArray.count; i++)
    {
        PFObject *object = oldArray[i];
        if (![newSet containsObject:object.objectId])
        {
            [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i + offset inSection:section]];
        }
    }
    for (int i = 0; i < newArray.count; i++)
    {
        PFObject *object = newArray[i];
        if (![oldSet containsObject:object.objectId])
        {
            [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:i + offset inSection:section]];
        }
    }
    
    if (indexPathsToAdd.count > 0 || indexPathsToRemove.count > 0)
    {
        [self beginUpdates];
        [self deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationAutomatic];
        [self insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationAutomatic];
        [self endUpdates];
    }
}

@end
