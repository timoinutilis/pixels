//
//  APIObject.h
//  Pixels
//
//  Created by Timo Kloss on 12/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APIObject : NSObject

@property (nonatomic, readonly) NSString *objectId;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic, readonly) NSDate *updatedAt;

+ (void)registerAPIClass;

+ (NSArray *)objectsFromArray:(NSArray<NSDictionary *> *)array;
+ (NSDictionary *)objectsByIdFromArray:(NSArray<NSDictionary *> *)array;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (void)updateWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dirtyDictionary;
- (void)clean;

@end

@interface NSDateFormatter (APIObject)

+ (NSDateFormatter *)APIDateFormatter;
+ (NSDateFormatter *)sharedAPIDateFormatter;

@end
