//
//  HelpContent.m
//  Pixels
//
//  Created by Timo Kloss on 26/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "HelpContent.h"

@interface HelpContent ()
@property NSArray *headerTags;
@property NSString *currentTag;
@property NSString *currentTagId;
@end

@implementation HelpContent

- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [super init])
    {
        self.headerTags = @[@"h1", @"h2", @"h3", @"h4", @"h5", @"h6"];
        _manualHtml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        _chapters = [NSMutableArray array];
        
        NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
        parser.delegate = self;
        [parser parse];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([self.headerTags indexOfObject:elementName.lowercaseString] != NSNotFound)
    {
        self.currentTag = elementName;
        self.currentTagId = attributeDict[@"id"];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.currentTag)
    {
        HelpChapter *chapter = [[HelpChapter alloc] init];
        chapter.title = string;
        chapter.htmlChapter = self.currentTagId;
        chapter.level = (int)[self.headerTags indexOfObject:self.currentTag.lowercaseString];
        [self.chapters addObject:chapter];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:self.currentTag])
    {
        self.currentTag = nil;
        self.currentTagId = nil;
    }
}

@end

@implementation HelpChapter

@end
