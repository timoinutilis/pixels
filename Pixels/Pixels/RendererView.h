//
//  RendererView.h
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Renderer;

@interface RendererView : UIView

@property Renderer *renderer;
@property BOOL shouldMakeSnapshots;

- (void)updateSnapshots;
- (UIImage *)imageFromBestSnapshot;
- (NSArray <UIImage *> *)imagesFromSnapshots:(int)amount;

@end
