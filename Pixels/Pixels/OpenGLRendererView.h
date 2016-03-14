//
//  OpenGLRendererView.h
//  Pixels
//
//  Created by Timo Kloss on 14/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class Renderer;

@interface OpenGLRendererView : GLKView

@property Renderer *renderer;

@end
