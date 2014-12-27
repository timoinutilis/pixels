//
//  HelpContent.h
//  Pixels
//
//  Created by Timo Kloss on 26/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HelpContent : NSObject <NSXMLParserDelegate>

@property (readonly) NSString *manualHtml;
@property (readonly) NSMutableArray *chapters;


- (instancetype)initWithURL:(NSURL *)url;

@end

@interface HelpChapter : NSObject
@property NSString *title;
@property NSString *htmlChapter;
@property int level;
@end
