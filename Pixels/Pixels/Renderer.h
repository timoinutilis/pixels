//
//  Renderer.h
//  Pixels
//
//  Created by Timo Kloss on 19/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Renderer : NSObject

@property (readonly) int size;
@property int colorIndex;

- (int)colorAtX:(int)x Y:(int)y;
- (void)clearWithColorIndex:(int)colorIndex;
- (void)plotX:(int)x Y:(int)y;
- (void)drawFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)drawBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)fillBoxFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY;
- (void)scrollFromX:(int)fromX Y:(int)fromY toX:(int)toX Y:(int)toY deltaX:(int)deltaX Y:(int)deltaY;
- (void)drawCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY;
- (void)fillCircleX:(int)x Y:(int)y radiusX:(int)radiusX radiusY:(int)radiusY;
- (void)drawText:(NSString *)text x:(int)x y:(int)y;
- (int)widthForText:(NSString *)text;

- (uint32_t)screenColorAtX:(int)x Y:(int)y;

@end
