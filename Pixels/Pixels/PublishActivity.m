//
//  PublishActivity.m
//  Pixels
//
//  Created by Timo Kloss on 28/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "PublishActivity.h"
#import "AFNetworking.h"
#import "Project.h"

@interface PublishActivity ()
@property Project *project;
@end

@implementation PublishActivity

+ (UIActivityCategory)activityCategory
{
    return UIActivityCategoryShare;
}

- (NSString *)activityType
{
    return @"PixelsShare";
}

- (NSString *)activityTitle
{
    return @"Pixels Community";
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"dummy_project_icon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    self.project = activityItems[0];
}

- (void)performActivity
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"secret": @"916486295",
                                 @"author": @"Author",
                                 @"title": self.project.name,
                                 @"description": @"Description",
                                 @"source_code": self.project.sourceCode};
    
    [manager POST:@"http://apps.timokloss.com/tools/pixelsshare.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self activityDidFinish:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [self activityDidFinish:NO];
        
    }];
}

@end
