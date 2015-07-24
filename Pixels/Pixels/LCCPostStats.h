//
//  LCCPostStats.h
//  Pixels
//
//  Created by Timo Kloss on 24/7/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Parse/Parse.h>

extern NSString *const LCCPostStatsLikesKey;
extern NSString *const LCCPostStatsDownloadsKey;
extern NSString *const LCCPostStatsCommentsKey;

@interface LCCPostStats : PFObject<PFSubclassing>

@property int numLikes;
@property int numDownloads;
@property int numComments;

@end
