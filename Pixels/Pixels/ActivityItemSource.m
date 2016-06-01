//
//  ActivityItemSource.m
//  Pixels
//
//  Created by Timo Kloss on 30/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "ActivityItemSource.h"
#import "Project.h"

@implementation ActivityItemSource

- (NSURL *)tempFileURL
{
    NSURL *dirURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    return [dirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.bas", self.project.name]];
}

// called to determine data type. only the class of the return type is consulted. it should match what -itemForActivityType: returns later
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return [self tempFileURL];
}

// called to fetch data after an activity is selected. you can return nil.
- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    NSURL *url = [self tempFileURL];
    NSData *data = [self.project.sourceCode dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToURL:url atomically:YES];
    
    return url;
}

// if activity supports a Subject field
- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return [NSString stringWithFormat:@"%@ for LowRes Coder", self.project.name];
}

// if activity supports preview image
- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size;
{
    if (self.project.iconData)
    {
        return [UIImage imageWithData:self.project.iconData];
    }
    return nil;
}

@end
